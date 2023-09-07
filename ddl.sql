-- Datenbankimplementierung

/*
Erstelle eine Datenbank, die Messwerte von Sensoren an verschiedenen Standorten festhalten. 
Grundlage für die Datenbank sind ein vorgegebenes ER-Diagramm sowie die nachfolgenden Stichpunkte für zusätzliche Integritätsbedingungen:
1. Primärschlüssel dürfen grundsätzlich nicht leer sein.
2. Es sollen nur Anbieter abgebildet werden können, die in Deutschland Umsatzsteuerpflichtig sind. Angabe von Name und Website verpflichtend.
3. Für Websiten und API-URLs soll sichergestellt werden, dass diese immer das HTTP-Protokoll (oder die gesicherte Version davon) benutzen.
4. Bundesland-Kürzel sollen nach dem ISO 3166-2 Standard formatiert werden. Nur deutsche Bundesländer können eingefügt werden. Alle Namen des Bundesländers sind unterschiedlich.
5. Koordinaten jedoch ausschließlich im EPSG-Code 4326 abgebildet werden können. 
   Es soll sichergestellt werden, dass eingegebene Koordinaten nicht außerhalb des entsprechenden Wertebereichs liegen. 
   Für jede Koordinate muss ein GeoHash und der EPSG-Code gespeichert werden.
6. GeoHashes sollen lediglich mit einer Präzision von 10cm × 10cm abgespeichert werden
7. Primärschlüssel für Stationen werden automatisch in aufsteigender Reihenfolge vergeben.
8. Der Abstand zwischen zwei Stationen muss immer definiert sein und kann nicht negativ sein.
9. Die „Messwert”-Generalisierung soll Attribut-sparend im Null-Stil abgebildet werden.
10. Die Windrichtung wird in Grad als ganze Zahl angegeben.
*/

CREATE TABLE Anbieter(
	UStID VARCHAR(11) NOT NULL PRIMARY KEY CHECK(UStID LIKE 'DE%' AND LENGTH(UStID) = 11),
	Name VARCHAR(30) NOT NULL,
	Website TEXT NOT NULL CHECK(Website LIKE 'http%',
    	Organisationsform VARCHAR(50),
    	API_URL TEXT CHECK(API_URL LIKE 'http%'),
    	Lizenz TEXT
	);

CREATE TABLE Bundesland(
	Kuerzel VARCHAR(5) NOT NULL PRIMARY KEY 
  	CHECK (Kuerzel LIKE 'DE-__'),
  	Name VARCHAR(30) UNIQUE NOT NULL,
  	Aufsichtsbehoerde VARCHAR(30)
	);

CREATE TABLE arbeitet_in(
	UStID VARCHAR(11) NOT NULL,
  	Kuerzel VARCHAR(5) NOT NULL,
  	-- Key --
    	PRIMARY KEY (UStID, Kuerzel),
    	FOREIGN KEY (UStID) REFERENCES Anbieter(UStID),
    	FOREIGN KEY (Kuerzel) REFERENCES Bundesland(Kuerzel)
	);

CREATE TABLE Koordinate(
	Latitude DECIMAL(8,6) NOT NULL CHECK (Latitude >= -90.0 AND Latitude <= 90.0),
  	Longitude DECIMAL(9,6) NOT NULL CHECK (Longitude >= -180.0 AND Longitude <= 180.0),
  	GeoHash TEXT NOT NULL CHECK (LENGTH(GeoHash) <= 12),
  	EPSG_Code INTEGER NOT NULL CHECK (EPSG_Code == 4326),
	Kuerzel CHAR(5),
    	-- Key --
    	FOREIGN KEY (Kuerzel) REFERENCES Bundesland(Kuerzel),
   	PRIMARY KEY (Latitude, Longitude)
	);

CREATE TABLE Polygon(
	Kuerzel VARCHAR(5) NOT NULL,
  	Latitude FLOAT NOT NULL,
  	Longitude FLOAT NOT NULL,
  	-- Key --
	PRIMARY KEY (Kuerzel, Latitude, Longitude),
  	FOREIGN KEY (Kuerzel) REFERENCES Bundesland(Kuerzel),
	FOREIGN KEY (Latitude, Longitude) REFERENCES Koordinate(Latitude, Longitude)
	);

CREATE TABLE Station(
	ID SERIAL NOT NULL PRIMARY KEY,
  	Hoehe DECIMAL(6,2),
  	UStID VARCHAR(11) NOT NULL,
  	Latitude FLOAT NOT NULL,
  	Longitude FLOAT NOT NULL,
  	-- Key --
  	FOREIGN KEY (UStID) REFERENCES Anbieter(UStID),
  	FOREIGN KEY (Latitude, Longitude) REFERENCES Koordinate(Latitude, Longitude)
	);
  	
CREATE TABLE verbunden_mit(
    	StationA_ID INT NOT NULL,
    	StationB_ID INT NOT NULL,
    	Abstand DECIMAL(10,2) NOT NULL CHECK (Abstand >= 0),
	-- Key --
    	PRIMARY KEY (StationA_ID, StationB_ID),
    	FOREIGN KEY (StationA_ID) REFERENCES Station(ID),
	FOREIGN KEY (StationB_ID) REFERENCES Station(ID)
	);

CREATE TABLE Messwert(
	Zeitpunkt DATETIME NOT NULL,
  	ID INT NOT NULL,
  	Einheit VARCHAR(30) NOT NULL,
  	Wert REAL NOT NULL,
  	Art VARCHAR(30),
  	Richtung INT,
  	hat_schatten BOOLEAN,
  	-- Key --
  	PRIMARY KEY (Zeitpunkt, ID),
  	FOREIGN KEY (ID) REFERENCES Station(ID)
  	Typ TEXT NOT NULL CHECK(Typ in ('Niederschlag', 'Wind', 'Sonne', 'Temperatur', 'Messwert')),
 	CHECK ((Typ = 'Niederschlag' AND Art IS NOT NULL AND Richtung IS NULL AND hat_schatten IS NULL)
	OR (Typ = 'Wind' AND Art IS NULL AND Richtung IS NOT NULL AND Richtung >= 0 AND Richtung <= 360 AND hat_schatten IS NULL)
        OR (Typ = 'Sonne' AND Art IS NULL AND Richtung IS NULL AND hat_schatten IS NOT NULL)
        OR (Typ = 'Temperatur' AND Art IS NULL AND Richtung IS NULL AND hat_schatten IS NULL)
        OR (Typ = 'Messwert' AND Art IS NULL AND Richtung IS NULL AND hat_schatten IS NULL))
	);
  
