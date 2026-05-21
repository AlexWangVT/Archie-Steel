"""
Mine Match — Interactive World Maps
====================================
Produces 4 standalone HTML maps using Plotly scatter_geo (no token required,
single world projection, works offline).

Maps generated:
    1. datasetA_world_map.html          — Dataset A locations
    2. datasetB_world_map.html          — Dataset B locations
    3. name_matching_quality_map.html   — Name score quality by location
    4. distance_matching_quality_map.html — Distance score quality by location

Usage:
    pip install pandas plotly openpyxl
    python mine_match_maps.py
"""

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

# =============================================================================
# 1. CONFIG
# =============================================================================

INPUT_FILE = (
    "../data/SPGlobalCaptialQ/"
    "Cloude_plant_name_match/"
    "plant_mine_matches.xlsx"
)

OUTPUT_DIR = (
    "../data/SPGlobalCaptialQ/"
    "Cloude_plant_name_match/"
)

# =============================================================================
# 2. LOAD & RENAME
# =============================================================================

df = pd.read_excel(INPUT_FILE)

df = df.rename(columns={
    "PROP_NAME (Dataset A)":    "name_a",
    "Lat A":                    "lat_a",
    "Lon A":                    "lon_a",
    "Matched Asset (Dataset B)":"name_b",
    "Lat B":                    "lat_b",
    "Lon B":                    "lon_b",
    "Name Score":               "name_score",
    "Distance Score":           "distance_score",
    "Distance (km)":            "distance_km",
    "Combined Confidence":      "combined_score",
    "Match Quality":            "match_quality",
})

# =============================================================================
# 3. QUALITY BANDS
# =============================================================================

def score_level(score):
    if score >= 90:   return "Very High"
    elif score >= 70: return "High"
    elif score >= 50: return "Medium"
    else:             return "Low"

df["name_level"]     = df["name_score"].apply(score_level)
df["distance_level"] = df["distance_score"].apply(score_level)

QUALITY_ORDER  = ["Very High", "High", "Medium", "Low"]
QUALITY_COLORS = {
    "Very High": "#1a9850",
    "High":      "#91cf60",
    "Medium":    "#fdae61",
    "Low":       "#d73027",
}

# =============================================================================
# 4. SHARED GEO LAYOUT
# =============================================================================

def geo_layout(title: str) -> dict:
    """Return a consistent layout dict for all scatter_geo figures."""
    return dict(
        title=dict(
            text=title,
            font=dict(family="Arial", size=16),
            x=0.5,
            xanchor="center",
        ),
        geo=dict(
            projection_type="natural earth",   # single-world, no token needed
            showland=True,
            landcolor="#e8ece6",
            showocean=True,
            oceancolor="#d4e8f5",
            showcountries=True,
            countrycolor="#c0c8b8",
            countrywidth=0.4,
            showcoastlines=True,
            coastlinecolor="#a0a896",
            coastlinewidth=0.5,
            showframe=False,
            bgcolor="white",
        ),
        paper_bgcolor="white",
        margin=dict(l=0, r=0, t=60, b=0),
        font=dict(family="Arial", size=13),
        height=700,
        legend=dict(
            title_font=dict(size=13),
            font=dict(size=12),
            borderwidth=1,
            bordercolor="#dddddd",
            bgcolor="rgba(255,255,255,0.85)",
        ),
    )

# =============================================================================
# 5. MAP A — Dataset A locations
# =============================================================================

figA = px.scatter_geo(
    df,
    lat="lat_a",
    lon="lon_a",
    hover_name="name_a",
    hover_data={
        "lat_a": ":.3f",
        "lon_a": ":.3f",
    },
    color_discrete_sequence=["#1f77b4"],
    title="<b>Dataset A — Capital IQ Mine Locations</b>",
)
figA.update_traces(
    marker=dict(size=6, opacity=0.75, line=dict(width=0.3, color="white")),
    name="Dataset A",
)
figA.update_layout(**geo_layout("Dataset A — Capital IQ Mine Locations"))
figA.write_html(OUTPUT_DIR + "datasetA_world_map.html")
figA.show()
print("Saved: datasetA_world_map.html")

# =============================================================================
# 6. MAP B — Dataset B locations
# =============================================================================

figB = px.scatter_geo(
    df,
    lat="lat_b",
    lon="lon_b",
    hover_name="name_b",
    hover_data={
        "lat_b": ":.3f",
        "lon_b": ":.3f",
    },
    color_discrete_sequence=["#d62728"],
    title="<b>Dataset B — Global Tracker Mine Locations</b>",
)
figB.update_traces(
    marker=dict(size=6, opacity=0.75, line=dict(width=0.3, color="white")),
    name="Dataset B",
)
figB.update_layout(**geo_layout("Dataset B — Global Tracker Mine Locations"))
figB.write_html(OUTPUT_DIR + "datasetB_world_map.html")
figB.show()
print("Saved: datasetB_world_map.html")

# =============================================================================
# 7. MAP C — Name match quality
# =============================================================================

figC = px.scatter_geo(
    df,
    lat="lat_b",
    lon="lon_b",
    color="name_level",
    hover_name="name_b",
    hover_data={
        "name_a":        True,
        "name_score":    ":.1f",
        "combined_score":":.1f",
        "lat_b":         False,
        "lon_b":         False,
    },
    category_orders={"name_level": QUALITY_ORDER},
    color_discrete_map=QUALITY_COLORS,
    title="<b>Dataset B — Name Matching Quality</b>",
)
figC.update_traces(
    marker=dict(size=7, opacity=0.85, line=dict(width=0.3, color="white")),
)
figC.update_layout(
    **geo_layout("Dataset B — Name Matching Quality"),
    legend_title_text="Name score",
)
figC.write_html(OUTPUT_DIR + "name_matching_quality_map.html")
figC.show()
print("Saved: name_matching_quality_map.html")

# =============================================================================
# 8. MAP D — Distance match quality
# =============================================================================

figD = px.scatter_geo(
    df,
    lat="lat_b",
    lon="lon_b",
    color="distance_level",
    hover_name="name_b",
    hover_data={
        "name_a":        True,
        "distance_score":":.1f",
        "distance_km":   ":.1f",
        "combined_score":":.1f",
        "lat_b":         False,
        "lon_b":         False,
    },
    category_orders={"distance_level": QUALITY_ORDER},
    color_discrete_map=QUALITY_COLORS,
    title="<b>Dataset B — Distance Matching Quality</b>",
)
figD.update_traces(
    marker=dict(size=7, opacity=0.85, line=dict(width=0.3, color="white")),
)
figD.update_layout(
    **geo_layout("Dataset B — Distance Matching Quality"),
    legend_title_text="Distance score",
)
figD.write_html(OUTPUT_DIR + "distance_matching_quality_map.html")
figD.show()
print("Saved: distance_matching_quality_map.html")

# =============================================================================
# 9. BONUS: Combined A+B overlay (both datasets on one map)
# =============================================================================

figE = go.Figure()

figE.add_trace(go.Scattergeo(
    lat=df["lat_a"],
    lon=df["lon_a"],
    mode="markers",
    name="Dataset A",
    marker=dict(
        size=6,
        color="#1f77b4",
        opacity=0.65,
        line=dict(width=0.3, color="white"),
    ),
    hovertemplate=(
        "<b>%{customdata[0]}</b><br>"
        "Lat: %{lat:.3f} | Lon: %{lon:.3f}<extra>Dataset A</extra>"
    ),
    customdata=df[["name_a"]].values,
))

figE.add_trace(go.Scattergeo(
    lat=df["lat_b"],
    lon=df["lon_b"],
    mode="markers",
    name="Dataset B",
    marker=dict(
        size=6,
        color="#d62728",
        opacity=0.65,
        symbol="triangle-up",
        line=dict(width=0.3, color="white"),
    ),
    hovertemplate=(
        "<b>%{customdata[0]}</b><br>"
        "Lat: %{lat:.3f} | Lon: %{lon:.3f}<extra>Dataset B</extra>"
    ),
    customdata=df[["name_b"]].values,
))

figE.update_layout(
    **geo_layout("Dataset A (●) vs Dataset B (▲) — All Locations Overlay"),
    legend_title_text="Dataset",
)
figE.write_html(OUTPUT_DIR + "combined_overlay_map.html")
figE.show()
print("Saved: combined_overlay_map.html")

print("\nAll 5 maps saved successfully.")