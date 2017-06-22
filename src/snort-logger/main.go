package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"time"

	"github.com/jasonish/go-unified2"
)

func main() {
	dirs := flag.String("dirs", "", "comma-separated list of log directories")
	tempdir := flag.String("tempdir", os.Getenv("TMPDIR"), "temporary directory")
	prefix := flag.String("prefix", "snort.log", "snort log prefix")
	outfile := flag.String("outfile", "", "output file")

	flag.Parse()

	if *dirs == "" || *tempdir == "" || *outfile == "" {
		fmt.Println("usage: snort-logger --dirs dir1,dir2 --tempdir /tmp --prefix snort.log --outfile snort.prom")
		os.Exit(99)
	}

	ticker := time.NewTicker(60 * time.Second)
	events := make(chan string)
	errs := make(chan error)

	for _, dir := range strings.Split(*dirs, ",") {
		go spool(unified2.NewSpoolRecordReader(dir, *prefix), events, errs)
	}
	go write(*tempdir, *outfile, events, ticker, errs)

	err := <-errs

	ticker.Stop()
	close(events)
	close(errs)
	log.Fatal(err)
}

func spool(reader *unified2.SpoolRecordReader, events chan string, errs chan error) {
	for {
		record, err := reader.Next()
		if err != nil {
			if err == io.EOF {
				time.Sleep(time.Millisecond)
			} else {
				errs <- err
			}
		}

		if record == nil {
			time.Sleep(time.Millisecond)
			continue
		}

		switch record := record.(type) {
		case *unified2.EventRecord:
			events <- format(record)
		}
	}
}

func write(tempdir, outfile string, events chan string, ticker *time.Ticker, errs chan error) {
	var counts map[string]int
	for {
		select {
		case event := <-events:
			counts[event]++
		case <-ticker.C:
			if err := flush(tempdir, outfile, counts); err != nil {
				errs <- err
			}
		}
	}
}

func format(event *unified2.EventRecord) string {
	return fmt.Sprintf(`sid="%d",ip_source="%s",ip_dest="%s",port_source="%d",port_dest="%d"`,
		event.SignatureId, event.IpSource.String(), event.IpDestination.String(), event.SportItype, event.DportIcode)
}

func flush(tempdir, outfile string, counts map[string]int) error {
	tmp, err := ioutil.TempFile(tempdir, "snort-log")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	for labels, count := range counts {
		if _, err := tmp.Write([]byte(fmt.Sprintf("snort_alert_count{%s} %d\n", labels, count))); err != nil {
			return err
		}
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), outfile)
}
