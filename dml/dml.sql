-- Datenbankerweiterung

/*
Eine halbfertige Datenbank ist gebgeben. 
Erstellen Sie anschließend die notwendigen SQL-Ausdrücke, um die Datenbank so zu modifizieren, dass sie die Vorgaben erfüllt.

Informationen zum Datenbankentwurf
===========================================================================================================================================================================================================================================================================================
1. Es gibt genau drei Arten von Mitarbeiter_in: Manager_in, Sekretaer_in und Facharbeiter_in. 
2. Jede_r hat ein eindeutiges Ordnungsmerkmal, einen Nachname, einen Vorname, ein Gehalt, und ein Anstellungsdatum (Angestellt_am).
    - Sekretär_innen und Facharbeiter_innen arbeiten in einer bestimmten Filiale (Arbeitet_in) und sind dieser seit einem gewissen Tag zugeordnet (Zugeordnet_seit).
    - Manager_innen unterscheiden sich von den anderen Mitarbeiter_innen, da pro Filiale nur ein_e Manager_in zuständig ist (Zustaendig_fuer). 
    - Das Datum der Filialzugehörigkeit wird auch für Manager_innen gespeichert (Zugeordnet_seit).
    - Facharbeiter_innen können zudem eine Abteilung haben. Sekretaer_innen können eine Fremdsprache sprechen.
    - Das Ordnungsmerkmal identifiziert die Rolle von Mitarbeiter_innen. Für Manager_innen muss das Merkmal mit einem "m" beginnen; für Facharbeiter_innen mit einem "f"; für Sekreträr_innen mit einem "s".
    - Für alle Mitarbeiter_innen soll zudem folgende Bedingung überprüft werden: Wenn Zugeordnet_seit ungleich NULL ist, dann muss das Datum in Zugeordnet_seit größer oder gleich Angestellt_am sein.
3. Eine Filiale hat eine FilialNr, eine Adresse, frei definierbare Oeffnungszeiten und eine Flaeche in (ganzen) Quadratmetern. Jede Filiale liegt außerdem in einem bestimmten Ort (Liegt_in).
    - Wenn eine Filiale gelöscht wird, sollen die zugehörigen Einträge in Arbeitet_in oder Zustaendig_fuer auf NULL gesetzt werden.
    - Darüber hinaus soll auch der Wert von Zugeordnet_seit auf NULL gesetzt werden, wenn eine Filiale gelöscht wird. 
    - Tipp: Ziehen Sie hierfür einen Trigger in Erwägung. Beachten Sie hierbei auch die unterschiedlichen Gruppen von Mitarbeiter_innen.
4. Ein Ort wird durch seine Postleitzahl (PLZ) identifiziert und hat darüber hinaus einen Ortsname.
5. Eine Produktgruppe wird durch ihre ProduktgruppenNr identifiziert und hat zusätzliche eine Bezeichnung.
6. Eine Produktgruppe kann in mehreren Filialen verfügbar sein (Verfuegbar_in). Gleichzeitig führt jede Filiale mehrere Produktgruppen. 
    - Für jede Kombination aus Filiale und Produktgruppe wird zudem gespeichert, Seit wann diese existiert.
    - Wenn eine Filiale oder eine Produktgruppe gelöscht wird, sollen auch die zugehörigen Einträge zu der jeweiligen Verfügbarkeit gelöscht werden.

Informationen aus dem Unternehmen
========================================================================================================================================================================================================================================================================================

Die Chefin findet den Null-Stil schrecklich.
Ihr Vorgesetzter hat irgendwann einmal entschieden, dass der Ortsname für alle Postleitzahlen im Berliner Bereich stets "Berlin" sein soll (unabhängig vom konkreten Ortsteil). Sie müssen diese Regel nur für bereits existierende Einträge sicherstellen.
Die Kollegin aus dem Gebäudemanagement hat Ihnen letztens noch stolz von den drei aktuellen Filialen im Unternehmen erzählt. Laut ihr liegt die größte Filiale des Unternehmens mit 800 m² in der Borsigstraße, direkt dahinter ist die Münchener Filiale mit 777 m². Die kleinste der drei Filialen hat 650 m².
Auf dem Tisch Ihres DBA-Kollegen haben Sie noch einen handschriftlichen Zettel mit einer Übersicht der Manager_innen im Unternehmen gefunden:
Ordnungsmerkmal	Name	                  Gehalt	Anstellungsdatum	  Filiale	    Seit
m10007	        Poepsel Lemaitre, Rudi	5000	  2016-05-01	           1	      2016-05-01
m10008	        Behme, Lennart	        6666	  1995-08-01	           2	      2001-09-01
m10009	        Lepping, Aljoscha Peter	5432	  2009-06-01	        München	    2010-10-01
*/

-- Change column's name from Trabajador to Facharbeiter_in
ALTER TABLE Trabajador RENAME TO Facharbeiter_in;

-- Table Manager_in
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
