from palettable.palette import Palette
from matplotlib.colors import Colormap
import numpy as np


def legendgram(
    f,
    ax,
    y,
    breaks,
    pal,
    bins=50,
    clip=None,
    loc="lower left",
    legend_size=(0.27, 0.2),
    frameon=False,
    tick_params=None,
):
    """
    Add a histogram in a choropleth with colors aligned with map

    Vendored and adapted from https://github.com/pysal/legendgram by @ljwolf licensed
    under BSD 3-Clause with Copyright (c) 2007-2015, PySAL Developers.
    ...
    Arguments
    ---------
    f           : Figure
    ax          : AxesSubplot
    y           : ndarray/Series
                  Values to map
    breaks      : list
                  Sequence with breaks for each class (i.e. boundary values
                  for colors)
    pal         : palettable colormap or matplotlib colormap
    clip        : tuple
                  [Optional. Default=None] If a tuple, clips the X
                  axis of the histogram to the bounds provided.
    loc         :   string or int
                    valid legend location like that used in matplotlib.pyplot.legend
    legend_size : tuple
                  tuple of floats between 0 and 1 describing the (width,height)
                  of the legend relative to the original frame.
    frameon     : bool (default: False)
                  whether to add a frame to the legendgram
    tick_params : keyword dictionary
                  options to control how the histogram axis gets ticked/labelled.
    Returns
    -------
    axis containing the legendgram.
    """
    k = len(breaks)
    histpos = make_location(ax, loc, legend_size=legend_size)
    histax = f.add_axes(histpos)
    N, bins, patches = histax.hist(y, bins=breaks, color="0.1")
    # ---
    if isinstance(pal, Palette):
        pl = pal.get_mpl_colormap()
    elif isinstance(pal, Colormap):
        pl = pal
    else:
        raise ValueError(
            "pal needs to be either palettable colormap or matplotlib colormap, got {}".format(
                type(pal)
            )
        )
    bucket_breaks = [0] + [np.searchsorted(bins, i) for i in breaks]
    for c in range(k):
        for b in range(bucket_breaks[c], bucket_breaks[c + 1]):
            patches[b].set_facecolor(pl(c / k))
    # ---
    if clip is not None:
        histax.set_xlim(*clip)
    histax.set_frame_on(frameon)
    histax.get_yaxis().set_visible(False)
    if tick_params is None:
        tick_params = dict()
    tick_params["labelsize"] = tick_params.get("labelsize", 12)
    histax.tick_params(**tick_params)
    return histax


def make_location(ax, loc, legend_size=(0.27, 0.2)):
    """
    Construct the location bounds of a legendgram
    Arguments:
    ----------
    ax          :   matplotlib.AxesSubplot
                    axis on which to add a legendgram
    loc         :   string or int
                    valid legend location like that used in matplotlib.pyplot.legend
    legend_size :   tuple or float
                    tuple denoting the length/width of the legendgram in terms
                    of a fraction of the axis. If a float, the legend is assumed
                    square.
    Returns
    -------
    a list [left_anchor, bottom_anchor, width, height] in terms of plot units
    that defines the location and extent of the legendgram.
    """
    position = ax.get_position()
    if isinstance(legend_size, float):
        legend_size = (legend_size, legend_size)
    lw, lh = legend_size
    legend_width = position.width * lw
    legend_height = position.height * lh
    right_offset = position.width - legend_width
    top_offset = position.height - legend_height
    anchor_x, anchor_y = position.x0 + 0.035, position.y0 + 0.04
    return [anchor_x, anchor_y, legend_width, legend_height]
