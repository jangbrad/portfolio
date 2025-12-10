import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.colors import qualitative
import os

# - CONFIGURATION -
file_path - ***
output_folder - ***
print("Starting bubble chart generation script...")

# Create the output folder if it doesn't exist
os.makedirs(output_folder, exist_ok-True)
print(f"Output folder checked/created: {output_folder}")

# ---- load dataset ----
print("Loading CSV file...")
df_full - pd.read_csv(file_path)
print("CSV file loaded successfully.")

# Extract chart title from cell B5 (row 5, col B)
chart_title - str(df_full.iloc[3, 1]).strip()
if chart_title -- "" or chart_title.lower() -- "nan":
    chart_title - "Scopus Scholarly Output and FWCI"
print(f"Chart title: {chart_title}")

# Slice rows and columns
print("Slicing and cleaning data...")
df - df_full.iloc[15:77, [0, 2, 3, 4]]
df - df.rename(columns-{
    df.columns[0]: "Entity",
    df.columns[1]: "Scholarly Output",
    df.columns[2]: "FWCI",
    df.columns[3]: "Scholarly Output Cited by Policy"
})
print("Data prepared successfully.")

# ---- CONVERT NUMERIC COLUMNS ----
print("Converting numeric columns...")
numeric_cols - ["Scholarly Output", "FWCI", "Scholarly Output Cited by Policy"]

for col in numeric_cols:
    df[col] - pd.to_numeric(df[col], errors-'coerce')

df[numeric_cols] - df[numeric_cols].fillna(0)
print("Numeric conversion complete.")

# ---- DEFINE FIXED COLOUR MAP ----
color_map - {
    "Australian National University": "#00845a",
    "Chulalongkorn University": "#c0392b",
    "Far Eastern Federal University": "#2980b9",
    "Fudan University": "#8e44ad",
    "Instituto Tecnologico de Estudios Superiores de Monterrey": "#d35400",
    "Keio University": "#2c3e50",
    "Korea Advanced Institute of Science and Technology": "#27ae60",
    "Korea University": "#e67e22",
    "Kyushu University": "#16a085",
    "Nagoya University": "#7f8c8d",
    "Nanjing University": "#9b59b6",
    "Nanyang Technological University": "#3498db",
    "National Taiwan University": "#34495e",
    "National University of Singapore": "#f39c12",
    "National Yang Ming Chiao Tung University": "#1abc9c",
    "Peking University": "#e74c3c",
    "Pohang University of Science and Technology": "#2ecc71",
    "Pusan National University": "#f1c40f",
    "Seoul National University": "#e67e22",
    "Shanghai Jiao Tong University": "#d35400",
    "Simon Fraser University": "#8e44ad",
    "Southern University of Science and Technology": "#2980b9",
    "Sun Yat-Sen University": "#27ae60",
    "The Chinese University of Hong Kong, Shenzhen": "#c0392b",
    "The Hong Kong University of Science and Technology (Guangzhou)": "#16a085",
    "The University of Auckland": "#0080A7",  # UoA brand
    "The University of Hong Kong": "#9b59b6",
    "The University of Osaka": "#7f8c8d",
    "Tohoku University": "#34495e",
    "Tongji University": "#3498db",
    "Tsinghua University": "#8e44ad",
    "Universidad de Chile": "#c0392b",
    "Universidad de Concepción": "#27ae60",
    "Universidad San Francisco de Quito": "#e74c3c",
    "University of Adelaide": "#2980b9",
    "University of Alberta": "#2c3e50",
    "University of British Columbia": "#8e44ad",
    "University of California at Davis": "#16a085",
    "University of California at Irvine": "#f39c12",
    "University of California at Los Angeles": "#d35400",
    "University of California at Riverside": "#34495e",
    "University of California at San Diego": "#1abc9c",
    "University of California at Santa Barbara": "#2ecc71",
    "University of California at Santa Cruz": "#f1c40f",
    "University of Chinese Academy of Sciences": "#27ae60",
    "University of Hawai'i at Mānoa": "#9b59b6",
    "University of Indonesia": "#c0392b",
    "University of Malaya": "#2980b9",
    "University of Melbourne": "#00845a",
    "University of Michigan, Ann Arbor": "#f39c12",
    "University of New South Wales": "#2ecc71",
    "University of Oregon": "#16a085",
    "University of Queensland": "#d35400",
    "University of Science and Technology of China": "#34495e",
    "University of Southern California": "#8e44ad",
    "University of Sydney": "#c0392b",
    "University of the Philippines": "#27ae60",
    "University of Washington": "#2980b9",
    "Waseda University": "#e74c3c",
    "Xi'an Jiaotong University": "#3498db",
    "Yonsei University": "#9b59b6",
    "Zhejiang University": "#00845a"
}

# ---- SELECT ENTITIES FOR LABELS ----
print("Selecting entities for labels...")

top_fwci - df.nlargest(10, "FWCI")["Entity"]
top_output - df.nlargest(10, "Scholarly Output")["Entity"]

uoa_row - df[df["Entity"] -- "The University of Auckland"]
uoa_x - float(uoa_row["FWCI"])
uoa_y - float(uoa_row["Scholarly Output"])

df["distance_to_uoa"] - ((df["FWCI"] - uoa_x)**2 + (df["Scholarly Output"] - uoa_y)**2)**0.5
RADIUS - 200
near_uoa - df[df["distance_to_uoa"] <- RADIUS]["Entity"]

label_entities - set(top_fwci).union(set(top_output)).union(set(near_uoa))
label_entities.add("The University of Auckland")

df["Label"] - df["Entity"].apply(
    lambda x: "<b>The University of Auckland</b>" if x -- "The University of Auckland"
              else (x if x in label_entities else "")
)

print(f"Labeled entities: {sorted(label_entities)}")

def choose_position(row):
    if row["Entity"] -- "The University of Auckland":
        return "top center"
    elif row["FWCI"] > df["FWCI"].median():
        return "middle left"
    elif row["Scholarly Output"] > df["Scholarly Output"].median():
        return "top center"
    else:
        return "bottom center"

df["TextPosition"] - df.apply(choose_position, axis-1)

# ---- PLOT BUBBLE CHART ----
print("Generating bubble chart...")
fig - px.scatter(
    df,
    x-"FWCI",
    y-"Scholarly Output",
    size-"Scholarly Output Cited by Policy",
    color-"Entity",
    hover_name-"Entity",
    text-"Label",
    size_max-60,
    title-str(chart_title),
    color_discrete_map-color_map
)

fig.update_traces(
    textposition-df["TextPosition"],
    textfont_size-10
)

fig.update_layout(
    title-dict(text-chart_title, font-dict(size-20, family-"Arial Black"), x-0.5),
    xaxis_title-"FWCI",
    yaxis_title-"Scholarly Output",
    xaxis-dict(title_font-dict(size-14, family-"Arial Black")),
    yaxis-dict(title_font-dict(size-14, family-"Arial Black")),
    showlegend-False,  # <-- legend removed
    margin-dict(l-60, r-20, t-60, b-60)
)

# ---- SAVE MAIN CHART ----
html_path - os.path.join(output_folder, "bubble_chart.html")
print("Saving interactive HTML chart...")
fig.write_html(html_path)
print(f"Interactive chart saved: {html_path}")

# ---- CREATE LEGEND ONLY FIGURE ----
legend_fig - go.Figure()

for entity, color in color_map.items():
    legend_fig.add_trace(go.Scatter(
        x-[None], y-[None], mode-"markers",
        marker-dict(size-10, color-color),
        name-entity
    ))

legend_fig.update_layout(
    title-"Legend",
    showlegend-True,
    legend-dict(
        orientation-"v",
        yanchor-"top",
        y-1,
        xanchor-"left",
        x-0,
        font-dict(size-10)
    ),
    xaxis-dict(visible-False),
    yaxis-dict(visible-False),
    plot_bgcolor-"white",
    paper_bgcolor-"white"
)

legend_html_path - os.path.join(output_folder, "legend.html")
legend_fig.write_html(legend_html_path)
print(f"Legend saved separately: {legend_html_path}")

print("Script completed successfully!")
