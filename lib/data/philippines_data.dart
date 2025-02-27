class PhilippinesData {
  static final Map<String, List<String>> provincesAndCities = {
    // Metro Manila (Complete)
    'Metro Manila': [
      'Manila', 'Quezon City', 'Makati', 'Pasig', 'Taguig', 'Pasay', 'Caloocan', 
      'Las Piñas', 'Malabon', 'Mandaluyong', 'Marikina', 'Muntinlupa', 
      'Navotas', 'Parañaque', 'San Juan', 'Valenzuela', 'Pateros'
    ],

    // Example of enhanced province data (Cebu)
    'Cebu': [
      'Cebu City', 'Mandaue City', 'Lapu-Lapu City', 'Talisay City', 
      'Danao City', 'Toledo City', 'Carcar City', 'Naga City',
      'Alcantara', 'Alcoy', 'Alegria', 'Aloguinsan', 'Argao', 'Asturias',
      'Badian', 'Balamban', 'Bantayan', 'Barili', 'Bogo', 'Boljoon',
      'Borbon', 'Carmen', 'Catmon', 'Compostela', 'Consolacion', 'Cordova',
      'Daanbantayan', 'Dalaguete', 'Dumanjug', 'Ginatilan', 'Liloan',
      'Madridejos', 'Malabuyoc', 'Medellin', 'Minglanilla', 'Moalboal',
      'Oslob', 'Pilar', 'Pinamungajan', 'Poro', 'Ronda', 'Samboan',
      'San Fernando', 'San Francisco', 'San Remigio', 'Santa Fe',
      'Santander', 'Sibonga', 'Sogod', 'Tabogon', 'Tabuelan', 'Tuburan',
      'Tudela'
    ],

    // Luzon - CAR
    'Abra': ['Bangued', 'La Paz', 'Lagangilang', 'Dolores', 'Tayum', 'Bucay'],
    'Apayao': ['Kabugao', 'Luna', 'Flora', 'Pudtol', 'Santa Marcela', 'Calanasan'],
    'Benguet': ['Baguio', 'La Trinidad', 'Itogon', 'Tuba', 'Tublay', 'Bokod'],
    'Ifugao': ['Lagawe', 'Kiangan', 'Lamut', 'Banaue', 'Hungduan', 'Mayoyao'],
    'Kalinga': ['Tabuk', 'Rizal', 'Pinukpuk', 'Tanudan', 'Lubuagan', 'Pasil'],
    'Mountain Province': ['Bontoc', 'Sagada', 'Bauko', 'Sabangan', 'Besao', 'Tadian'],

    // Luzon - Ilocos Region
    'Ilocos Norte': [
      'Laoag City', 'Batac City', 'Adams', 'Bacarra', 'Badoc', 'Bangui', 
      'Banna', 'Burgos', 'Carasi', 'Currimao', 'Dingras', 'Dumalneg', 
      'Marcos', 'Nueva Era', 'Pagudpud', 'Paoay', 'Pasuquin', 'Piddig', 
      'Pinili', 'San Nicolas', 'Sarrat', 'Solsona', 'Vintar'
    ],
    'Ilocos Sur': [
      'Vigan City', 'Candon City', 'Alilem', 'Banayoyo', 'Bantay', 
      'Burgos', 'Cabugao', 'Caoayan', 'Cervantes', 'Galimuyod', 
      'Gregorio del Pilar', 'Lidlidda', 'Magsingal', 'Nagbukel', 
      'Narvacan', 'Quirino', 'Salcedo', 'San Emilio', 'San Esteban', 
      'San Ildefonso', 'San Juan', 'San Vicente', 'Santa', 'Santa Catalina',
      'Santa Cruz', 'Santa Lucia', 'Santa Maria', 'Santiago', 'Santo Domingo',
      'Sigay', 'Sinait', 'Sugpon', 'Suyo', 'Tagudin'
    ],
    'La Union': [
      'San Fernando City', 'Agoo', 'Aringay', 'Bacnotan', 'Bagulin', 
      'Balaoan', 'Bangar', 'Bauang', 'Burgos', 'Caba', 'Luna', 
      'Naguilian', 'Pugo', 'Rosario', 'San Gabriel', 'San Juan', 
      'Santo Tomas', 'Santol', 'Sudipen', 'Tubao'
    ],
    'Pangasinan': [
      'Dagupan City', 'Alaminos City', 'San Carlos City', 'Urdaneta City',
      'Lingayen', 'Agno', 'Aguilar', 'Alcala', 'Anda', 'Asingan', 
      'Balungao', 'Bani', 'Basista', 'Bautista', 'Bayambang', 'Binalonan',
      'Binmaley', 'Bolinao', 'Bugallon', 'Burgos', 'Calasiao', 'Dasol',
      'Infanta', 'Labrador', 'Laoac', 'Lingayen', 'Mabini', 'Malasiqui',
      'Manaoag', 'Mangaldan', 'Mangatarem', 'Mapandan', 'Natividad',
      'Pozorrubio', 'Rosales', 'San Fabian', 'San Jacinto', 'San Manuel',
      'San Nicolas', 'San Quintin', 'Santa Barbara', 'Santa Maria',
      'Santo Tomas', 'Sison', 'Sual', 'Tayug', 'Umingan', 'Urbiztondo',
      'Villasis'
    ],

    // Luzon - Cagayan Valley
    'Batanes': ['Basco', 'Mahatao', 'Ivana', 'Uyugan', 'Sabtang', 'Itbayat'],
    'Cagayan': ['Tuguegarao', 'Aparri', 'Lal-lo', 'Ballesteros', 'Alcala'],
    'Isabela': [
      'Ilagan City', 'Santiago City', 'Cauayan City', 'Alicia', 'Angadanan',
      'Aurora', 'Benito Soliven', 'Burgos', 'Cabagan', 'Cabatuan', 
      'Cordon', 'Delfin Albano', 'Dinapigue', 'Divilacan', 'Echague',
      'Gamu', 'Jones', 'Luna', 'Maconacon', 'Mallig', 'Naguilian',
      'Palanan', 'Quezon', 'Quirino', 'Ramon', 'Reina Mercedes',
      'Roxas', 'San Agustin', 'San Guillermo', 'San Isidro', 'San Manuel',
      'San Mariano', 'San Mateo', 'San Pablo', 'Santa Maria', 'Santo Tomas',
      'Tumauini'
    ],
    'Nueva Vizcaya': ['Bayombong', 'Solano', 'Bambang', 'Bagabag', 'Dupax del Sur'],
    'Quirino': ['Cabarroguis', 'Diffun', 'Aglipay', 'Saguday', 'Maddela'],

    // Luzon - Central Luzon
    'Aurora': ['Baler', 'Casiguran', 'Dipaculao', 'Maria Aurora', 'San Luis'],
    'Bataan': ['Balanga', 'Mariveles', 'Limay', 'Orion', 'Pilar'],
    'Bulacan': ['Malolos', 'Meycauayan', 'San Jose del Monte', 'Baliuag', 'Plaridel'],
    'Nueva Ecija': ['Cabanatuan', 'San Jose', 'Gapan', 'Palayan', 'Science City of Muñoz'],
    'Pampanga': [
      'San Fernando City', 'Angeles City', 'Mabalacat City', 'Apalit', 
      'Arayat', 'Bacolor', 'Candaba', 'Floridablanca', 'Guagua', 
      'Lubao', 'Macabebe', 'Magalang', 'Masantol', 'Mexico', 
      'Minalin', 'Porac', 'San Luis', 'San Simon', 'Santa Ana', 
      'Santa Rita', 'Santo Tomas', 'Sasmuan'
    ],
    'Tarlac': ['Tarlac City', 'Paniqui', 'Concepcion', 'Capas', 'Gerona'],
    'Zambales': ['Olongapo', 'Iba', 'Subic', 'Castillejos', 'San Antonio'],

    // Luzon - CALABARZON
    'Batangas': [
      'Batangas City', 'Lipa City', 'Tanauan City', 'Santo Tomas City',
      'Agoncillo', 'Alitagtag', 'Balayan', 'Balete', 'Bauan', 'Calaca',
      'Calatagan', 'Cuenca', 'Ibaan', 'Laurel', 'Lemery', 'Lian',
      'Lobo', 'Mabini', 'Malvar', 'Mataas na Kahoy', 'Nasugbu',
      'Padre Garcia', 'Rosario', 'San Jose', 'San Juan', 'San Luis',
      'San Nicolas', 'San Pascual', 'Santa Teresita', 'Taal', 'Taysan',
      'Tingloy', 'Tuy'
    ],
    'Cavite': [
      'Bacoor City', 'Cavite City', 'Dasmariñas City', 'General Trias City',
      'Imus City', 'Tagaytay City', 'Trece Martires City', 'Alfonso',
      'Amadeo', 'Carmona', 'General Emilio Aguinaldo', 'General Mariano Alvarez',
      'Indang', 'Kawit', 'Magallanes', 'Maragondon', 'Mendez', 'Naic',
      'Noveleta', 'Rosario', 'Silang', 'Tanza', 'Ternate'
    ],
    'Laguna': [
      'Biñan City', 'Calamba City', 'San Pablo City', 'Santa Rosa City',
      'San Pedro City', 'Cabuyao City', 'Alaminos', 'Bay', 'Calauan',
      'Cavinti', 'Famy', 'Kalayaan', 'Liliw', 'Los Baños', 'Luisiana',
      'Lumban', 'Mabitac', 'Magdalena', 'Majayjay', 'Nagcarlan',
      'Paete', 'Pagsanjan', 'Pakil', 'Pangil', 'Pila', 'Rizal',
      'Santa Cruz', 'Santa Maria', 'Siniloan', 'Victoria'
    ],
    'Quezon': ['Lucena', 'Tayabas', 'Sariaya', 'Pagbilao', 'Lucban'],
    'Rizal': ['Antipolo', 'Cainta', 'Taytay', 'Rodriguez', 'San Mateo'],

    // Luzon - MIMAROPA
    'Marinduque': ['Boac', 'Mogpog', 'Gasan', 'Santa Cruz', 'Torrijos', 'Buenavista'],
    'Occidental Mindoro': ['San Jose', 'Mamburao', 'Sablayan'],
    'Oriental Mindoro': ['Calapan', 'Puerto Galera', 'Pinamalayan'],
    'Palawan': ['Puerto Princesa', 'Coron', 'El Nido', 'Brookes Point'],
    'Romblon': ['Romblon', 'Odiongan', 'San Fernando'],

    // Luzon - Bicol Region
    'Albay': ['Legazpi', 'Tabaco', 'Ligao', 'Daraga'],
    'Camarines Norte': ['Daet', 'Labo', 'Jose Panganiban'],
    'Camarines Sur': ['Naga', 'Iriga', 'Pili', 'Sipocot'],
    'Catanduanes': ['Virac', 'San Andres', 'Baras'],
    'Masbate': ['Masbate City', 'Aroroy', 'Cataingan'],
    'Sorsogon': ['Sorsogon City', 'Bulan', 'Gubat'],

    // Visayas - Western Visayas
    'Aklan': ['Kalibo', 'Boracay', 'New Washington'],
    'Antique': ['San Jose', 'Sibalom', 'Bugasong'],
    'Capiz': ['Roxas', 'Panay', 'Pontevedra'],
    'Guimaras': ['Jordan', 'Nueva Valencia', 'Buenavista'],
    'Iloilo': [
      'Iloilo City', 'Passi City', 'Ajuy', 'Alimodian', 'Anilao',
      'Badiangan', 'Balasan', 'Banate', 'Barotac Nuevo', 'Barotac Viejo',
      'Batad', 'Bingawan', 'Cabatuan', 'Calinog', 'Carles', 'Concepcion',
      'Dingle', 'Dueñas', 'Dumangas', 'Estancia', 'Guimbal', 'Igbaras',
      'Janiuay', 'Lambunao', 'Leganes', 'Lemery', 'Leon', 'Maasin',
      'Miagao', 'Mina', 'New Lucena', 'Oton', 'Pavia', 'Pototan',
      'San Dionisio', 'San Enrique', 'San Joaquin', 'San Miguel',
      'San Rafael', 'Santa Barbara', 'Sara', 'Tigbauan', 'Tubungan',
      'Zarraga'
    ],
    'Negros Occidental': [
      'Bacolod City', 'Bago City', 'Cadiz City', 'Escalante City',
      'Himamaylan City', 'Kabankalan City', 'La Carlota City',
      'Sagay City', 'San Carlos City', 'Silay City', 'Sipalay City',
      'Talisay City', 'Victorias City', 'Binalbagan', 'Calatrava',
      'Candoni', 'Cauayan', 'Enrique B. Magalona', 'Hinigaran',
      'Hinoba-an', 'Ilog', 'Isabela', 'La Castellana', 'Manapla',
      'Moises Padilla', 'Murcia', 'Pontevedra', 'Pulupandan',
      'Salvador Benedicto', 'San Enrique', 'Toboso', 'Valladolid'
    ],

    // Visayas - Central Visayas
    'Bohol': ['Tagbilaran', 'Tubigon', 'Jagna'],
    'Negros Oriental': ['Dumaguete', 'Bais', 'Tanjay'],
    'Siquijor': ['Siquijor', 'Larena', 'Maria'],

    // Visayas - Eastern Visayas
    'Biliran': ['Naval', 'Caibiran', 'Kawayan'],
    'Eastern Samar': ['Borongan', 'Guiuan', 'Dolores'],
    'Leyte': ['Tacloban', 'Ormoc', 'Baybay'],
    'Northern Samar': ['Catarman', 'Allen', 'Laoang'],
    'Samar': ['Catbalogan', 'Calbayog', 'Basey'],
    'Southern Leyte': ['Maasin', 'Sogod', 'Liloan'],

    // Mindanao - Zamboanga Peninsula
    'Zamboanga del Norte': ['Dipolog', 'Dapitan', 'Sindangan'],
    'Zamboanga del Sur': ['Pagadian', 'Zamboanga City', 'Ipil'],
    'Zamboanga Sibugay': ['Ipil', 'Kabasalan', 'Siay'],

    // Mindanao - Northern Mindanao
    'Bukidnon': ['Malaybalay', 'Valencia', 'Quezon'],
    'Camiguin': ['Mambajao', 'Mahinog', 'Sagay'],
    'Lanao del Norte': ['Iligan', 'Tubod', 'Kapatagan'],
    'Misamis Occidental': ['Oroquieta', 'Ozamiz', 'Tangub'],
    'Misamis Oriental': ['Cagayan de Oro', 'Gingoog', 'El Salvador'],

    // Mindanao - Davao Region
    'Davao de Oro': ['Nabunturan', 'Maco', 'Mawab'],
    'Davao del Norte': ['Tagum', 'Panabo', 'Samal'],
    'Davao del Sur': ['Digos', 'Davao City', 'Santa Cruz'],
    'Davao Occidental': ['Malita', 'Santa Maria', 'Don Marcelino'],
    'Davao Oriental': ['Mati', 'Lupon', 'Banaybanay'],

    // Mindanao - SOCCSKSARGEN
    'Cotabato': ['Kidapawan', 'Kabacan', 'Midsayap'],
    'Sarangani': ['Alabel', 'Glan', 'Malapatan'],
    'South Cotabato': ['Koronadal', 'General Santos', 'Polomolok'],
    'Sultan Kudarat': ['Isulan', 'Tacurong', 'Lebak'],

    // Mindanao - CARAGA
    'Agusan del Norte': ['Butuan', 'Cabadbaran', 'Buenavista'],
    'Agusan del Sur': ['San Francisco', 'Prosperidad', 'Bayugan'],
    'Dinagat Islands': ['San Jose', 'Dinagat', 'Basilisa'],
    'Surigao del Norte': ['Surigao City', 'Siargao', 'Dapa'],
    'Surigao del Sur': ['Tandag', 'Bislig', 'Lianga'],

    // BARMM
    'Basilan': ['Isabela City', 'Lamitan', 'Tipo-Tipo'],
    'Lanao del Sur': ['Marawi', 'Malabang', 'Wao'],
    'Maguindanao del Norte': ['Datu Odin Sinsuat', 'Sultan Kudarat'],
    'Maguindanao del Sur': ['Buluan', 'Datu Paglas'],
    'Sulu': ['Jolo', 'Maimbung', 'Patikul'],
    'Tawi-Tawi': ['Bongao', 'Panglima Sugala', 'Mapun'],
  };

  static List<String> get provinces => provincesAndCities.keys.toList()..sort();
  
  static List<String> getCities(String province) {
    return provincesAndCities[province] ?? [];
  }
}
