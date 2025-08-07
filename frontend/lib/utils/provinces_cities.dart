// lib/utils/provinces_cities.dart
class ProvincesCities {
  static const Map<String, List<String>> provincesCities = {
    "Buenos Aires": [
      "La Plata", "Mar del Plata", "Bahía Blanca", "Tandil", "Olavarría", 
      "Pergamino", "Junín", "Azul", "Necochea", "San Nicolás", "Campana",
      "Zárate", "Luján", "Mercedes", "Chivilcoy", "Balcarce", "Dolores",
      "Chascomús", "San Pedro", "Ramallo", "Baradero", "Arrecifes"
    ],
    "Catamarca": [
      "San Fernando del Valle de Catamarca", "Andalgalá", "Belén", 
      "Santa María", "Tinogasta", "Fiambalá"
    ],
    "Chaco": [
      "Resistencia", "Barranqueras", "Fontana", "Puerto Vilelas", 
      "Presidencia Roque Sáenz Peña", "Villa Ángela", "Charata"
    ],
    "Chubut": [
      "Rawson", "Comodoro Rivadavia", "Puerto Madryn", "Trelew", 
      "Esquel", "Puerto Deseado", "Caleta Olivia"
    ],
    "Córdoba": [
      "Córdoba", "Villa Carlos Paz", "Río Cuarto", "San Francisco", 
      "Villa María", "Alta Gracia", "Jesús María", "La Falda", 
      "Cruz del Eje", "Bell Ville", "Marcos Juárez"
    ],
    "Corrientes": [
      "Corrientes", "Goya", "Mercedes", "Paso de los Libres", 
      "Curuzú Cuatiá", "Monte Caseros", "Esquina"
    ],
    "Entre Ríos": [
      "Paraná", "Concordia", "Gualeguaychú", "Concepción del Uruguay", 
      "Victoria", "Villaguay", "Crespo", "Chajarí"
    ],
    "Formosa": [
      "Formosa", "Clorinda", "Pirané", "El Colorado", "Ingeniero Juárez"
    ],
    "Jujuy": [
      "San Salvador de Jujuy", "Palpalá", "Libertador General San Martín", 
      "Perico", "El Carmen", "San Pedro"
    ],
    "La Pampa": [
      "Santa Rosa", "General Pico", "Toay", "Realicó", "Eduardo Castex", 
      "Intendente Alvear"
    ],
    "La Rioja": [
      "La Rioja", "Chilecito", "Aimogasta", "Chepes", "Chamical"
    ],
    "Mendoza": [
      "Mendoza", "San Rafael", "Godoy Cruz", "Guaymallén", "Las Heras", 
      "Maipú", "Luján de Cuyo", "San Martín", "Rivadavia", "Tunuyán"
    ],
    "Misiones": [
      "Posadas", "Oberá", "Eldorado", "Puerto Iguazú", "Montecarlo", 
      "Apóstoles", "Leandro N. Alem", "Puerto Rico"
    ],
    "Neuquén": [
      "Neuquén", "Plottier", "Cipolletti", "Cutral Có", "Zapala", 
      "Villa La Angostura", "San Martín de los Andes", "Centenario"
    ],
    "Río Negro": [
      "Viedma", "San Carlos de Bariloche", "General Roca", "Cipolletti", 
      "Villa Regina", "Río Colorado", "Choele Choel"
    ],
    "Salta": [
      "Salta", "San Ramón de la Nueva Orán", "Tartagal", "Metán", 
      "Cafayate", "Güemes", "Rosario de Lerma"
    ],
    "San Juan": [
      "San Juan", "Chimbas", "Rivadavia", "Santa Lucía", "Pocito", 
      "Rawson", "Caucete", "Jáchal"
    ],
    "San Luis": [
      "San Luis", "Villa Mercedes", "Merlo", "La Punta", "Justo Daract", 
      "Concarán"
    ],
    "Santa Cruz": [
      "Río Gallegos", "Caleta Olivia", "Puerto Deseado", "El Calafate", 
      "Pico Truncado", "Puerto San Julián"
    ],
    "Santa Fe": [
      "Santa Fe", "Rosario", "Rafaela", "Reconquista", "Venado Tuerto", 
      "Villa Gobernador Gálvez", "Esperanza", "Santo Tomé", "Casilda"
    ],
    "Santiago del Estero": [
      "Santiago del Estero", "La Banda", "Termas de Río Hondo", 
      "Añatuya", "Frías", "Monte Quemado"
    ],
    "Tierra del Fuego": [
      "Ushuaia", "Río Grande", "Tolhuin"
    ],
    "Tucumán": [
      "San Miguel de Tucumán", "Yerba Buena", "Tafí Viejo", "Concepción", 
      "Banda del Río Salí", "Alderetes", "Aguilares"
    ]
  };

  static List<String> get provinces => provincesCities.keys.toList();

  static List<String> getCitiesByProvince(String province) {
    return provincesCities[province] ?? [];
  }
}