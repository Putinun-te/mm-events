"""Shared layout settings for the architecture diagrams."""

GRAPH_ATTR = {
    "fontsize": "22",
    "fontname": "DejaVu Sans",
    "pad": "0.4",
    "nodesep": "0.7",
    "ranksep": "1.0",
    "splines": "spline",
    "bgcolor": "white",
}

NODE_ATTR = {"fontname": "DejaVu Sans", "fontsize": "12"}
EDGE_ATTR = {"fontname": "DejaVu Sans", "fontsize": "11", "color": "#555555"}


def diagram_kwargs(title, filename):
    return {
        "name": title,
        "filename": filename,
        "outformat": "png",
        "show": False,
        "direction": "LR",
        "graph_attr": GRAPH_ATTR,
        "node_attr": NODE_ATTR,
        "edge_attr": EDGE_ATTR,
    }
