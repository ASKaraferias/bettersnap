local resize        = require("awful.mouse.resize")
local aplace        = require("awful.placement")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local color         = require("gears.color")
local shape         = require("gears.shape")
local cairo         = require("lgi").cairo

local capi          = {
    mouse = mouse,
    screen = screen,
    client = client,
}

local module        = {
    default_distance = 8
}
local snapper_gap   = beautiful.snapper_gap or 0
local placeholder_w = nil

local function show_placeholder(geo)
    if not geo then
        if placeholder_w then
            placeholder_w.visible = false
        end
        return
    end

    placeholder_w = placeholder_w or wibox {
        ontop = true,
        bg    = color(beautiful.snap_bg or beautiful.bg_urgent or "#ff0000"),
    }

    placeholder_w:geometry(geo)

    local img = cairo.ImageSurface(cairo.Format.A1, geo.width, geo.height)
    local cr = cairo.Context(img)

    cr:set_operator(cairo.Operator.CLEAR)
    cr:set_source_rgba(0, 0, 0, 1)
    cr:paint()
    cr:set_operator(cairo.Operator.SOURCE)
    cr:set_source_rgba(1, 1, 1, 1)

    local line_width = beautiful.snap_border_width or 5
    cr:set_line_width(beautiful.xresources.apply_dpi(line_width))

    local f = beautiful.snap_shape or function()
        cr:translate(line_width, line_width)
        shape.rounded_rect(cr, geo.width - 2 * line_width, geo.height - 2 * line_width, 10)
    end

    f(cr, geo.width, geo.height)

    cr:stroke()

    placeholder_w.shape_bounding = img._native
    img:finish()

    placeholder_w.visible = true
end

local function build_placement(snap)
    return aplace.scale + aplace[snap]
    + ( aplace["maximize"] or nil)
end

local function detect_screen_edges(c, snap)
    local coords = capi.mouse.coords()
    local sg = capi.mouse.screen.geometry
    local h, v = false, false
    local hindex, vindex = -1, -1
    local hincr = sg.width / 8
    local vincr = sg.height / 6

    local hlist = {math.abs(coords.x - sg.x),
                    math.abs((sg.x + sg.width) - coords.x)}
    local vlist = {math.abs(coords.y - sg.y),
                    math.abs((sg.y + sg.height) - coords.y)}

    local hdist = hlist[1] <= hlist[2] and hlist[1] or hlist[2]
    local vdist = vlist[1] <= vlist[2] and vlist[1] or vlist[2]

    h = (hdist <= snap)
    v = (vdist <= snap)

    if v and not h then
        if hdist <= hincr then hindex = 1
        elseif hdist <= 2 * hincr then hindex = 2
        elseif hdist <= 3 * hincr then hindex = 3
        else hindex = 4 end
        if (vdist < 2 ) and hdist > 3.8 * hincr then
            hindex = 5
        end
    elseif h and not v then
        if vdist <= vincr then vindex = 1
        elseif vdist <= 2 * vincr then vindex = 2
        else vindex = 3 end
    elseif h and v then
        hindex, vindex = 0, 0
    end

    local hloc = hlist[1] <= hlist[2] and "left" or "right"
    local vloc = vlist[1] <= vlist[2] and "top" or "bottom"


    return h, v, hindex, vindex, hloc, vloc
end

local current_snap = nil

local function get_geometry(hindex, vindex, hloc, vloc)
    local geo = { x = 0, y = 0, width = 0, height = 0 }
    local sw = capi.mouse.screen.workarea

    if hindex == 0 and vindex == 0 then
        geo.width = sw.width / 2 - 1.5 * snapper_gap
        geo.height = sw.height / 2 - 1.5 * snapper_gap
        if hloc == "left" then
            geo.x = sw.x + snapper_gap
        else
            geo.x = sw.x + sw.width / 2 + 0.5 * snapper_gap
        end
        if vloc == "top" then
            geo.y = sw.y + snapper_gap
        else
            geo.y = sw.y + sw.height / 2 + 0.5 * snapper_gap
        end
    else
        geo.y = sw.y + snapper_gap
        geo.height = sw.height - 2 * snapper_gap
        if hindex == 5 then
            geo.x = sw.x + snapper_gap
            geo.width = sw.width - 2 * snapper_gap
        elseif hindex == 1 then
            geo.width = sw.width * 2/3 - 1.5 * snapper_gap
            if hloc == "left" then geo.x = sw.x + snapper_gap
            else geo.x = sw.x + sw.width * 1/3 + 0.5 * snapper_gap end
        elseif hindex == 2 then
            geo.width = sw.width * 3/4 - 1.5 * snapper_gap
            if hloc == "left" then geo.x = sw.x + snapper_gap
            else geo.x = sw.x + 1/4 * sw.width + 0.5 * snapper_gap end
        elseif hindex == 3 then
            geo.width = sw.width/2 - snapper_gap
            geo.x = sw.x + sw.width * 1/4 + 0.5 * snapper_gap
        elseif hindex == 4 then
            geo.width = sw.width/3 - snapper_gap
            geo.x = sw.x + sw.width/3 + 0.5 * snapper_gap
        elseif vindex == 3 then
            geo.width = sw.width / 4 - 1.5 * snapper_gap
            if hloc == "left" then geo.x = sw.x + snapper_gap
            else geo.x = sw.x + sw.width * 3/4 + 0.5 * snapper_gap end
        elseif vindex == 2 then
            geo.width = sw.width * 1/3 - 1.5 * snapper_gap
            if hloc == "left" then geo.x = sw.x + snapper_gap
            else geo.x = sw.x + sw.width * 2/3 + 0.5 * snapper_gap end
        elseif vindex == 1 then
            geo.width = sw.width / 2 - 1.5 * snapper_gap
            if hloc == "left" then geo.x = sw.x + snapper_gap
            else geo.x = sw.x + sw.width / 2 + 0.5 * snapper_gap end
        end
    end
    return geo
end

local function detect_modernsnap(c, distance, show)
    local old_snap = current_snap
    local h, v, hindex, vindex, hloc, vloc
        = detect_screen_edges(c, distance)

    if v or h then
        current_snap = {hindex, vindex, hloc, vloc}
    else
        current_snap = nil
    end

    if old_snap == current_snap then
        return
    end

    -- Show the expected geometry outline
    local geometry = current_snap and get_geometry(hindex, vindex, hloc, vloc)
    if show then
        show_placeholder(geometry or nil)
    end
    return geometry
end

local function apply_bettersnap(c, args, geo)
    if not current_snap then return end

    -- Remove the move offset
    args.offset = {}

    placeholder_w.visible = false
    return build_placement(current_snap)(c, {
        to_percent    = 1,
        bounding_rect = geo
    })
end


local geometry = { x = 0, y = 0, width = 100, height = 100 }
-- Enable edge snapping
resize.add_move_callback(function(c, geo, args)
    -- Screen edge snapping (bettersnap)
    if (module.edge_enabled ~= false)
        and args and (args.snap == nil or args.snap) then
        local geotmp = detect_modernsnap(c, 30, true)
        if geotmp then geometry = geotmp end
    end
end, "mouse.move")

-- Apply the snap
resize.add_leave_callback(function(c, _, args)
    if module.edge_enabled == false then return end
    return apply_bettersnap(c, args, geometry)
end, "mouse.move")

-- awful.mouse.add_leave_callback adds a callback executed when the mousegrabber
-- stops.

return setmetatable(module, { __call = function(_, ...) return module.snap(...) end })
