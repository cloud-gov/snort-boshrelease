package main

import (
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
	dirs := os.Getenv("DIRS")
	tempdir := os.Getenv("TMP_DIR")
	prefix := os.Getenv("PREFIX")
	output := os.Getenv("OUTPUT")

	ticker := time.NewTicker(60 * time.Second)
	events := make(chan string)
	errs := make(chan error)

	for _, dir := range strings.Split(dirs, ",") {
		go spool(unified2.NewSpoolRecordReader(dir, prefix), events, errs)
	}
	go write(tempdir, output, events, ticker, errs)

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

func write(tempdir, output string, events chan string, ticker *time.Ticker, errs chan error) {
	var buffer []string
	for {
		select {
		case event := <-events:
			buffer = append(buffer, event)
			if len(buffer) > 100 {
				if err := flush(tempdir, output, buffer); err != nil {
					errs <- err
				}
			}
		case <-ticker.C:
			if err := flush(tempdir, output, buffer); err != nil {
				errs <- err
			}
		}
	}
}

func format(record *unified2.EventRecord) string {
	payload := fmt.Sprintf(`sid="%d",ip_source="%s",ip_dest="%s",port_source="%d",port_dest="%d"`,
		record.SignatureId, record.IpSource.String(), record.IpDestination.String(), record.SportItype, record.DportIcode)
	return fmt.Sprintf("snort_alert{%s} %d %d", payload, 1, record.EventSecond*1000+record.EventMicrosecond/1000)
}

func flush(tempdir, output string, buffer []string) error {
	tmp, err := ioutil.TempFile(tempdir, "snort-log")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	buffer = append(buffer, "") // Add trailing newline
	if _, err := tmp.Write([]byte(strings.Join(buffer, "\n"))); err != nil {
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), output)
}
