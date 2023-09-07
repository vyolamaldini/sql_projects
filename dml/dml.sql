-- Datenbankerweiterung

/*
Eine halbfertige Datenbank ist gegeben. 
Erstellen Sie anschließend die notwendigen SQL-Ausdrücke, um die Datenbank so zu modifizieren, dass sie die Vorgaben erfüllt.
Mehrere Infos dazu: https://isis.tu-berlin.de/mod/quiz/review.php?attempt=3192207&cmid=1598907
*/

-- Change column's name from Trabajador to Facharbeiter_in
ALTER TABLE Trabajador RENAME TO Facharbeiter_in;

-- Create non-existing table for Manager
CREATE TABLE Manager_in (
    Ordnungsmerkmal VARCHAR(255) NOT NULL PRIMARY KEY,
    Nachname VARCHAR(255) NOT NULL,
    Vorname VARCHAR(255) NOT NULL,
    Gehalt INTEGER NOT NULL,
    Angestellt_am DATE NOT NULL,
    Zustaendig_fuer SMALLINT UNIQUE,
    Zugeordnet_seit DATE,
    FOREIGN KEY (Zustaendig_fuer) REFERENCES Filiale (FilialNr)
    ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK (Ordnungsmerkmal LIKE 'm%'),
    CHECK ((Zugeordnet_seit IS NULL) OR (Zugeordnet_seit >= Angestellt_am))
);

-- Inserting new values
INSERT INTO Manager_in VALUES
('m10007', 'Poepsel Lemaitre', 'Rudi', 5000, '2016-05-01', 1, '2016-05-01'),
('m10008', 'Behme', 'Lennart', 6666,'1995-08-01', 2, '2001-09-01'),
('m10009', 'Lepping', 'Aljoscha Peter', 5432, '2009-06-01', 3, '2010-10-01');

-- Add new column to a table
ALTER TABLE Filiale ADD Flaeche INTEGER CHECK (Flaeche >= 0);

-- Set the values for the new column
UPDATE Filiale SET Flaeche = 800 WHERE FilialNr = 1;
UPDATE Filiale SET Flaeche = 650 WHERE FilialNr = 2;
UPDATE Filiale SET Flaeche = 777 WHERE FilialNr = 3;
UPDATE Ort SET Ortsname = "Berlin" where PLZ LIKE "1%";

CREATE TRIGGER filiale_trigger
BEFORE DELETE ON Filiale
FOR EACH ROW
BEGIN
    UPDATE Facharbeiter_in
    SET Arbeitet_in = NULL, 
	Zugeordnet_seit = NULL
    WHERE Arbeitet_in = OLD.FilialNr;
    
    UPDATE Sekretaer_in
    SET Arbeitet_in = NULL,
	Zugeordnet_seit = NULL
    WHERE Arbeitet_in = OLD.FilialNr;
    
    UPDATE Manager_in
    SET Zustaendig_fuer = NULL,
	Zugeordnet_seit = NULL
    WHERE Zustaendig_fuer = OLD.FilialNr;  
END;

-- Table Verfuegbar_in
CREATE TABLE Verfuegbar_in (
    FilialNr SMALLINT NOT NULL,
    ProduktgruppenNr INT NOT NULL,
    Seit DATE,
    PRIMARY KEY (FilialNr, ProduktgruppenNr),
    FOREIGN KEY (FilialNr) REFERENCES Filiale(FilialNr) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ProduktgruppenNr) REFERENCES Produktgruppe(ProduktgruppenNr) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TRIGGER trigger1
BEFORE DELETE ON Filiale
FOR EACH ROW
BEGIN  
    DELETE FROM Verfuegbar_in WHERE FilialNr = OLD.FilialNr;
END;

CREATE TRIGGER trigger2
BEFORE DELETE ON Produktgruppe
FOR EACH ROW
BEGIN  
    DELETE FROM Verfuegbar_in WHERE ProduktgruppenNr = OLD.ProduktgruppenNr;
END;
