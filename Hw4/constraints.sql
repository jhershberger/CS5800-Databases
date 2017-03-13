--Consraint 1
--Change default value for ab to 20
ALTER TABLE batting 
        ALTER COLUMN ab DROP DEFAULT,
        ALTER COLUMN ab SET DEFAULT 20;
        
 --Test Contraint 1
 INSERT INTO batting (ab)
        VALUES(DEFAULT);
        
 --Constraint 2 
 --Players cannot have more hits than at bats
 ALTER TABLE batting 
        ADD CONSTRAINT hits CHECK(h <= ab);
        
--test constraint 2
INSERT INTO batting (h,ab)
        VALUES(30, 2);
        
--Constraint 3
--League can only have Nl or AL as the value
ALTER TABLE batting
        ADD CONSTRAINT nl_al CHECK(UPPER(lgid) = 'NL' OR UPPER(lgid) = 'AL');
        
 --Test Constraint 3
 INSERT INTO batting (lgid)
        VALUES('JH');
        
        
--Constraint4 
--Delete all records for teams who lost more than 161 games in a season
CREATE OR REPLACE FUNCTION losses() RETURNS trigger AS '
        BEGIN 
                IF NEW.l > 161 THEN
                        DELETE FROM teams AS t WHERE (t.teamid = NEW.teamid);
                END IF;
                RETURN NEW;
        END;
' LANGUAGE plpgsql;

CREATE TRIGGER del_team 
        AFTER INSERT OR UPDATE ON teams
                FOR EACH ROW EXECUTE PROCEDURE losses();
        
--Test constraint4
INSERT INTO teams (l,name, teamid, yearid)
        VALUES(162, 'testing', 'BLN', 1980);
UPDATE teams SET l = 162 WHERE teamid = 'BLN' AND yearid = 1980;
SELECT * FROM teams WHERE teamid = 'BLN';


--constraint 5
--if a player wins the mvp, ws mvp, and gold glove in the same season then add them 
-- to the HoF
CREATE OR REPLACE FUNCTION hof() RETURNS TRIGGER AS '
       BEGIN 
                WITH awrd AS (
                        SELECT masterid, awardid, yearid, row_number() OVER (PARTITION BY masterid, yearid ORDER BY yearid) AS awrds
                        FROM awardsplayers
                        WHERE awardid = $$Gold Glove$$ OR awardid = $$Most Valuable Player$$ OR awardid = $$World Series MVP$$
                ), mid AS (
                        SELECT DISTINCT ON (a.masterid) a.masterid, a.yearid
                        FROM awrd AS a 
                        JOIN awrd AS b ON (a.masterid = b.masterid AND b.yearid = a.yearid AND a.awardid != b.awardid)
                        JOIN awrd AS c ON (a.masterid = c.masterid AND c.yearid = a.yearid AND c.awardid != a.awardid AND c.awardid != b.awardid)
                        WHERE (a.awrds >= 3)
                )
                INSERT INTO halloffame (masterid, yearid)
                        SELECT masterid, yearid FROM mid WHERE (masterid NOT IN (SELECT masterid FROM halloffame));
                RETURN NEW;
        END;
                
' LANGUAGE plpgsql;

CREATE TRIGGER hall
        AFTER INSERT OR UPDATE 
        ON awardsplayers 
        EXECUTE PROCEDURE hof();
        
--test constraint5 
INSERT INTO awardsplayers (awardid, yearid, masterid)
        VALUES ('Most Valuable Player', 1994, 'jhersh');
SELECT * FROM halloffame WHERE (masterid = 'jhersh');

--constraint6
--team name can't be null
ALTER TABLE teams
        ALTER COLUMN name SET NOT NULL;
--Test constraint6
INSERT INTO teams (name)
        VALUES(null);
        
--Constraint 7
-- everyone must have a unique name
ALTER TABLE master ADD CONSTRAINT uname UNIQUE(namefirst, namelast);

--Test constraint 7
INSERT INTO master (masterID, namefirst, namelast)
        VALUES('jhersh', 'Babe', 'Ruth');
        
