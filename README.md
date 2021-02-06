Converts an iCalendar file (presumably produced by `calcurse`) to
an SVG file suitable for printing, aligning events according to time.

By default it uses A4 paper in portrait mode, showing 4 days worth of events.

If events have CATEGORIES, they can be colorized.

Typical usage:

```
	./ical2svg.pl mycalendar.ics 2021-02-05 categories.txt > mycalendar.svg
```

The `categories.txt` file should contain stroke and fill colors for each
category. The category string must match exactly what's in the iCalendar
file, including any commas if an event has multiple categories. Here's
an example:

```
p darkgreen green
w darkred red
p,w darkblue blue
```

It would make sense to use my "tagging" branch of `calcurse` until it has
proper tagging support (that is, if you need coloring).
