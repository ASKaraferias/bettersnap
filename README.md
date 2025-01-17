# bettersnap

This is a patch and partial rewrite of AwesomeWM's aweful.mouse.snap module that
provides aerosnap (screen edge snapping) functionality for floating windows.

This has some important advantages over the default awesomeWM module:

* Unlike the AwesomeWM's edge snapping it is compatible with the
  beautiful.snapper_gap variable (meaning that it has configurable useless gaps)
* It has more snapping options and is suited for use with modern larger screens.
* More generic way of screen edge detection that allows for more subdivisions of
  each edge than top, bottom, left, right, top-left, top-right, bottom-left,
  bottom right, that can be configured by the user.


https://github.com/user-attachments/assets/a0eae7b1-c528-4d98-b812-cd91e5acbd95


## Usage

### Installation

To install, run: 

```
cd $HOME/.config/awesome
git clone https://github.com/ASKaraferias/bettersnap.git
```

### Basic Usage

Add these lines to your `rc.lua`:

``` 
local bettersnap = require("bettersnap")
bettersnap.snap.edge_enabled = true

-- And disable the default snapping functionality like so:
awful.mouse.snap.edge_enabled = false
awful.mouse.snap.client_enabled = false
```

### Theme Variables

* `beautiful.snap_bg`, type *color*: The snap outline background color.
* `beautiful.snap_border_width`, type *integer*: The snap outline width.
* `beautiful.snap_shape`, type *shape* (a `gears.shape` compatible function):
  The snap outline shape.
* `beautiful.snapper_gap`, type *number*, default 0: The gap that separates the
  snapping surfaces with eachother (for example the gap between the surface that
  takes the left third of the workarea with the surface that thake the right two
  thirds, or between the surface that take the right half with the surface that
  takes the left half) and with the workarea edge.
