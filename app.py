import os
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

# configuración inicial de la página
ruta_actual = os.path.dirname(__file__)
ruta_icono = os.path.join(ruta_actual, "assets", "banner.svg")

st.set_page_config(
    page_title="Perfiles de riesgo en Colisiones de Tránsito en California",
    page_icon=ruta_icono,
    layout="wide",
    initial_sidebar_state="expanded",
)

# contenido principal
ruta_imagen = os.path.join(ruta_actual, "assets", "banner.svg")

# banner en la parte superior de la página
if os.path.exists(ruta_imagen):
  st.image(ruta_imagen, use_container_width=True)

st.markdown("<br>", unsafe_allow_html=True)

# sección de descripción en columnas
col1, col2 = st.columns([1.8, 1.2], gap="large")

with col1:
  st.markdown("### Acerca del Proyecto")
  st.markdown("""
    Esta plataforma interactiva recopila la investigación descriptiva e inferencial sobre colisiones de tránsito en California 
    durante el período decenal **2010–2019** a partir del registro oficial **SWITRS** 
    (*Statewide Integrated Traffic Records System*), administrado por la **California Highway Patrol (CHP)**.
    """)

