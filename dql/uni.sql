-- SQL-DQL Aufgabe, Uni-Schema. 

-- Formuliere einen SQL-Ausdruck, der äquivalent zu der jeweiligen Aussage.
-- mehrere Infos dazu: https://isis.tu-berlin.de/mod/quiz/review.php?attempt=3242341&cmid=1522474#question-3714214-10

/* 
Aufgabe 1:
==========================================================================================================================================================================
Alle Studierenden, sowie die Anzahl der Prüfungen, welche die Studierenden jeweils nicht bestanden haben, 
geteilt durch die Anzahl aller von ihnen angetretenen Prüfungen.
Ergebnisschema: [ Name(↑2), Anteil(↓1) ]
Geben Sie nur die ersten 10 Zeilen aus.
==========================================================================================================================================================================
*/

SELECT Name, 
    CAST(COUNT(CASE WHEN Note > 4.0 THEN 1 END) AS FLOAT) --Anzahl der bestandenen Prüfungen
    / COUNT(Note) -- geteilt durch Anzahl der angetretenen Prüfüngen 
    AS Anteil 
FROM Studenten
LEFT JOIN Pruefen ON Studenten.MatrNr = Pruefen.MatrNr
GROUP BY Name
HAVING Anteil IS NOT NULL
ORDER BY Anteil DESC, Name ASC
LIMIT 10;

/* 
Aufgabe 2:
==========================================================================================================================================================================
Name der Assistent*innen, deren Professor*innen Vorlesungen lesen, in denen mindestens eine, 
aber insgesamt weniger als drei Personen durchgefallen sind. Jeder Name soll nur einmal im Ergebnis enthalten sein.
Ergebnisschema: [ Name(↑1) ]
==========================================================================================================================================================================
*/

SELECT DISTINCT a.Name
FROM Assistenten a

WHERE a.Boss IN (
    SELECT v.gelesenVon FROM Vorlesungen v
    JOIN pruefen p ON p.VorlNr = v.VorlNr
    WHERE pr.Note > 4.0
    GROUP BY pr.PersNr
    HAVING COUNT(*) < 3
)
ORDER BY a.Name ASC;

/* 
Aufgabe 3:
==========================================================================================================================================================================
Name jeder Vorlesung sowie die Anzahl der Studierenden, die sie hören.
Ergebnisschema: [ Titel(↑2), Anzahl(↓1) ]
==========================================================================================================================================================================
*/

SELECT v.Titel, COUNT (h.MatrNr) AS Anzahl
FROM Vorlesungen v 
LEFT JOIN Hoeren h ON h.VorlNr = v.VorlNr
GROUP BY v.titel
ORDER BY Anzahl DESC, 
         v.Titel ASC;

/* 
Aufgabe 4:
==========================================================================================================================================================================
Der Name aller Studierenden, die ein Modul hören, ohne alle Nachfolgemodule gehört zu haben, 
sowie der Name der Module und deren Nachfolger.
Tipp: Erstellen Sie pro Nachfolgemodul einen eigenen Eintrag.
Ergebnisschema: [ Name(↑1), Titel(↑2), Nachfolgertitel(↑3) ]
Geben Sie nur die ersten 10 Zeilen aus. Hängen Sie dafür LIMIT 10 an Ihre Query ran.
==========================================================================================================================================================================
*/

SELECT Name, v1.Titel, v2.Titel AS Nachfolgertitel
FROM Studenten s,
     Vorlesungen v1,
     Vorlesungen v2,
     Voraussetzen vor,
     Hoeren h
WHERE s.MatrNr=h.MatrNr
  AND h.VorlNr = v1.VorlNr
  AND v2.VorlNr NOT IN(
  SELECT VorlNr
  FROM Hoeren h2
  WHERE s.MatrNr = h2.MatrNr
  )
  AND vor.Nachfolger = v2.VorlNr
  AND vor.Vorgaenger = v1.VorlNr
  AND h.VorlNr != v2.VorlNr
ORDER BY Name ASC,
         v1.Titel ASC,
         Nachfolgertitel ASC
LIMIT 10

/* 
Aufgabe 5:
==========================================================================================================================================================================
Die Namen der Studierenden mit einem besseren Notendurchschnitt als dem Durchschnitt der Durchschnittsnoten aller Studierenden, 
sowie dessen Durchschnittsnote. Für die Durchschnittsnote werden nur die bestandenen Prüfungen gezählt (also keine Prüfung mit Note 5.0).
Ergebnisschema: [ Name(↑2), Durchschnitt(↑1) ]
Geben Sie nur die ersten 10 Zeilen aus. Hängen Sie dafür LIMIT 10 an Ihre Query ran.
==========================================================================================================================================================================
*/

SELECT s.Name, AVG(p.Note) AS Durchschnitt
FROM Pruefen p
JOIN Studenten s ON s.MatrNr = p.MatrNr
WHERE p.Note < 5.0
GROUP BY s.Name

HAVING AVG(p.Note) < (
    SELECT AVG(mittelwert)
    FROM (
        SELECT AVG(p.Note) AS mittelwert
        FROM Pruefen p
		JOIN Studenten s ON s.MatrNr = p.MatrNr
        WHERE p.Note < 5.0
        GROUP BY s.Name
        ) as subquery
)

ORDER BY Durchschnitt ASC, s.Name ASC
LIMIT 10;

/* 
Aufgabe 6:
==========================================================================================================================================================================
Der Name aller Professoren sowie der Name der Studierenden, deren Durchschnittsnote beim Professor die Beste ist, sowie die Note selbst.
Ergebnisschema: [Professor(↑2), Student(↑3), Note(↑1)]
Geben Sie nur die ersten 10 Zeilen aus. Hängen Sie dafür LIMIT 10 an Ihre Query ran.
==========================================================================================================================================================================
*/

SELECT p.Name AS Professor, s.Name AS Student, CAST (pr.Note AS FLOAT) AS Note
FROM Studenten s
JOIN Pruefen pr ON s.MatrNr = pr.MatrNr
JOIN Professoren p ON pr.PersNr = p.PersNr

WHERE pr.Note in (
	SELECT MIN(AvgNote)
  	FROM (
      SELECT AVG(Note) AS AvgNote
  		FROM Pruefen 
  		WHERE PersNr = p.PersNr
  		GROUP BY MatrNr
      ) AS Durchschnittsnoten
)

GROUP BY p.Name, s.Name
ORDER BY pr.Note ASC, AVG(pr.Note) DESC, p.Name ASC, s.Name ASC
LIMIT 10;

/* 
Aufgabe 7:
==========================================================================================================================================================================
Geben Sie die Namen der Professor*innen an, die nur an einem Fachgebiet tätig sind, sowie die Anzahl der durch die Professor*innen betreuten Vorlesungen, 
an denen nur Studierende teilnehmen, die vor dem sechsten Semester sind, sowie die dazugehörigen Fachgebiete. 
Filtern Sie Einträge für Professor*innen raus, die keine Vorlesung betreuen, bei der nur Studierende teilnehmen die vor dem sechsten Semester sind.
Ergebnisschema: [Name(↑2), AnzahlVorlesungen(↓1), Fachgebiet]
Geben Sie nur die ersten 10 Zeilen aus. Hängen Sie dafür LIMIT 10 an Ihre Query ran.
==========================================================================================================================================================================
*/

SELECT p.Name, COUNT(DISTINCT h.VorlNr) AS AnzahlVorlesungen, a.Fachgebiet
FROM Professoren p
JOIN Assistenten a ON a.boss = p.PersNr
JOIN Vorlesungen v ON p.PersNr = v.gelesenVon
JOIN Hoeren h ON v.VorlNr = h.VorlNr
JOIN Studenten s ON h.MatrNr = s.MatrNr

-- Vorlesungen herausgefiltert, an denen mindestens ein Student mit 
-- einem Semester größer oder gleich 6 teilnimmt.

WHERE v.VorlNr NOT IN (
    SELECT DISTINCT h.VorlNr
    FROM Hoeren h
    JOIN Studenten s ON s.MatrNr = h.MatrNr
    WHERE s.Semester >= 6
)
GROUP BY p.name
HAVING COUNT(DISTINCT Fachgebiet) = 1 
ORDER BY AnzahlVorlesungen DESC, p.Name ASC
LIMIT 10
