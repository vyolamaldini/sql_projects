-- SQL-DQL Aufgabe, Uni-Schema. 

-- Formuliere einen SQL-Ausdruck, der äquivalent zu der jeweiligen Aussage.
-- mehrere Infos dazu: https://isis.tu-berlin.de/mod/quiz/review.php?attempt=3242341&cmid=1522474#question-3714214-10

/* 
Aufgabe 1:
==========================================================================================================================================================================
Geben Sie die E-Mail-Adressen der Nutzer*innen an, die das Profil mit der ID '1' nach dem Datum ‘2023-05-01’ besucht haben und mindestens ein Bild gepostet haben.
Ergebnisschema: [email(↑3), letzterBesuch(↓2), anzahlBilder(↓1)]
==========================================================================================================================================================================
*/

-- eigene Antwort
SELECT n.email, b.letzter_besuch AS letzterBesuch, COUNT(po.Typ) AS anzahlBilder
FROM Nutzer_in n

LEFT JOIN besucht b ON n.email = b.email
LEFT JOIN postet_auf pa ON n.email = pa.email
LEFT JOIN Post po ON pa.PostID = po.ID

WHERE b.ProfilID = '1' AND po.Typ = 'Bild'
AND b.letzter_besuch > '2023-05-01'

GROUP BY n.email
HAVING COUNT(CASE WHEN po.Typ = 'Bild' THEN 1 END) >= 1 
ORDER BY anzahlBilder DESC,  b.letzter_besuch DESC, b.email ASC
LIMIT 1

-- Lösung
WITH profil_1_besucht AS
  (SELECT *
   FROM besucht
   WHERE ProfilID == 1
     AND letzter_besuch > "2023-05-01 10:00:00" )
SELECT profil_1_besucht.email,
       letzter_besuch AS letzterBesuch,
       Count(Bild) AS anzahlBilder
FROM profil_1_besucht,
     postet_auf,
     Post
WHERE profil_1_besucht.email == postet_auf.email
  AND postet_auf.PostID == Post.ID
  AND Post.Bild NOT NULL
GROUP BY profil_1_besucht.email
ORDER BY profil_1_besucht.email DESC
LIMIT 10;

/* 
Aufgabe 2:
==========================================================================================================================================================================
Geben Sie die Vor- und Nachnamen der Profile an, die zwei verschiedene Arten von Posts (Text und Bild) gepostet haben, sowie die Gesamtanzahl der Posts dieser Profile.
Ergebnisschema:
[Vorname(↑2), Nachname(↑3), GesamtZahlPosts(↓1)]
Geben Sie nur die ersten 10 Zeilen aus.
==========================================================================================================================================================================
*/

SELECT prof.Vorname, prof.Nachname, COUNT(*) AS GesamtZahlPosts
FROM Profil prof
JOIN postet_auf pa ON pa.ProfilID = prof.ID
JOIN Post po ON pa.PostID = po.ID

WHERE po.Typ IN ('Text', 'Bild')
GROUP BY prof.Vorname, prof.Nachname
HAVING COUNT(DISTINCT po.Typ) = 2 -- zwei verschiedene Arten von Posts (Text und Bild) gepostet
ORDER BY GesamtZahlPosts DESC, prof.Vorname ASC, prof.Nachname ASC
LIMIT 10

/* 
Aufgabe 3:
==========================================================================================================================================================================
Geben Sie die Namen der Gruppen(Circles) von der “Freundesliste”-Tabelle mit der Gesamtanzahl der Posts für jede Gruppe 
und der durchschnittlichen Breite der Bildposts in dieser Gruppe an. Geben Sie nur Gruppen an, die mindestens zwei Bildposts haben.
Runden Sie den Wert der durchschnittlichen Bildbreite auf zwei Nachkommastellen.
Ergebnisschema: [Circle(↑3), GesamtZahlPosts(↓2), DurchschnittlicheBildBreite(↓1)]
==========================================================================================================================================================================
*/

SELECT fl.Circle, COUNT(po.Bild) AS GesamtAnzahlPosts, ROUND(AVG(po.Breite),2) AS DurchschnittlicheBildBreite
FROM Freundesliste fl
JOIN existiert_in ei ON ei.ID = fl.ID
JOIN Nutzer_in n ON ei.email = n.email
JOIN postet_auf pa ON n.email = pa.email
JOIN Post po ON pa.PostID = po.ID

GROUP BY fl.Circle
HAVING COUNT(po.Bild) >= 2
ORDER BY DurchschnittlicheBildBreite DESC, GesamtAnzahlPosts DESC, fl.Circle ASC
LIMIT 10

/* 
Aufgabe 4:
==========================================================================================================================================================================
Die Namen der Freundeslisten, in denen Leute sind, die mehr Bilder als Text gepostet haben, sowie die Email-Adresse der Person, die mehr Bilder als Text gepostet hat. 
Falls für einen Freundeskreis mehrere Personen in Frage kommen, geben Sie nur die Email-Adresse der Person an, die die kürzeste E-Mail-Adresse hat.
Ergebnisschema: [CIRCLE(↑1), email(↓2)]
==========================================================================================================================================================================
*/

SELECT ei.circle AS CIRCLE, ei.email 
FROM existiert_in ei

WHERE ei.email IN (
	SELECT pa.email
  	FROM postet_auf pa 
	JOIN Post po ON pa.PostID = po.ID 
    GROUP BY pa.email
    HAVING COUNT(CASE WHEN po.Typ = 'Text' THEN 1 END) < COUNT(CASE WHEN po.Typ = 'Bild' THEN 1 END)
)

GROUP BY ei.Circle
HAVING LENGTH(ei.email) = MIN(LENGTH(ei.email))
ORDER BY ei.Circle ASC, ei.email DESC
LIMIT 10

/* 
Aufgabe 5:
=======================================================================================================================================================================================
Der/Die jüngste Nutzer*in aus jeder Freundesliste, mit seiner/ihrer E-Mail-Adresse, dem Zeitpunkt, seit der/die Nutzer*in existiert, und allen Text Posts dieses/dieser Nutzer*in.
Vor den Text Posts soll jeweils noch "Text: " stehen (z.B. "Text: This is a text post." statt nur "This is a text post.").
Wenn mehrere Nutzer*innen als jüngste Nutzer*in in Frage kommen, dann sollen für alle jüngsten Nutzer*innen Ergebnisse ausgegeben werden.
Wenn eine jüngste Nutzer*in keine Text Posts verfasst hat, dann soll diese nicht ausgegeben werden. Es kann vorkommen, dass für manche Freundeslisten keine Nutzer*in ausgegeben wird.
Ergebnisschema: [Circle(↑2), email(↓3), seit(↓1), Text(↓4)]
=======================================================================================================================================================================================
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
Aufgabe 6:
===============================================================================================================================================================================
Geben Sie die E-Mail-Adressen der Benutzer*innen aus, die in mindestens drei unterschiedlichen Freundeslisten Mitglied sind und mindestens eines dieser Profile besucht haben. 
Geben Sie zusätzlich das Verhältnis der Anzahl der Freundeslisten, bei denen der/die Nutzer*in auch das dazugehörige Profil besucht hat, 
und der Anzahl aller Freundeslisten in denen der/die Nutzer*in existiert als REAL Wert an.
Beispiel: Eine/Ein Nutzer*in ist in der 'Friends' und in der 'Family' Freundesliste. Besucht hat diese/dieser Nutzer*in allerdings nur das Profil der 'Friends' Freundesliste. 
Dadurch ergibt sich ein Verhältnis von 1/2 = 0.5.
Runden Sie das Verhältnis auf zwei Nachkommastellen ab.
Ergebnisschema: [email(↓2), besuchtRatio(↓1)]
===============================================================================================================================================================================
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
Aufgabe 7:
==========================================================================================================================================================================
Geben Sie Name, Vorname, die Anzahl der geposteten Bildposts und Textposts, sowie das aktuellste Datum eines Profilbesuchs für die Profile an, die Freundeslisten haben, 
in denen alle Nutzer*innen sind, an.
[Vorname(↑4), Nachname(↑5), TextPosts(↓2), BildPosts(↓3), letzterBesuch(↑1)]
==========================================================================================================================================================================
*/

WITH alle_nutzer AS (
    SELECT ID, Circle
    FROM Freundesliste
    GROUP BY ID, Circle
    HAVING COUNT(ID) = (SELECT COUNT(email) FROM Nutzer_in)
),
Freundeslisten AS (
    SELECT ID, Circle
    FROM existiert_in
    GROUP BY ID, Circle
    HAVING COUNT(email) = (SELECT COUNT(email) FROM Nutzer_in)
)
SELECT prof.Vorname, prof.Nachname,
    COUNT(CASE WHEN po.Typ = 'Text' THEN 1 END) AS TextPosts,
    COUNT(CASE WHEN po.Typ = 'Bild' THEN 1 END) AS BildPosts,
    b.letzter_besuch AS letzterBesuch

FROM Profil prof
JOIN Freundeslisten fl ON prof.ID = fl.ID 
LEFT JOIN besucht b ON b.ProfilID = prof.ID
LEFT JOIN postet_auf pa ON pa.ProfilID = prof.ID
LEFT JOIN Post po ON pa.PostID = po.ID
GROUP BY prof.ID, prof.Vorname, prof.Nachname, b.letzter_besuch
ORDER BY letzterBesuch ASC, TextPosts DESC, BildPosts DESC, prof.Vorname ASC, prof.Nachname ASC

LIMIT 10;
