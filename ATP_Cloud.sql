use defaultdb;

# Top 10 de temporadas más dominantes por porcentaje de victorias
CREATE OR REPLACE VIEW defaultdb.vw_Stats_Season AS (
    WITH Tabla_Crudo AS (
        SELECT 
            winner_name AS player,
            --Extraemos los 4 dígitos antes del guion y los volvemos número
            CAST(SUBSTRING_INDEX(tourney_id, '-', 1) AS UNSIGNED) AS year_tournament,
            surface AS Superficie,
            tourney_name AS Torneo,
            tourney_level AS Nivel_Torneo,
            indoor AS Indoor_Outdoor,
            w_ace AS aces,
            w_df AS double_faults,
            minutes,
            winner_rank AS `rank`,      
            winner_ht AS height,
            w_1stIn AS first_in,
            w_1stWon AS first_won,
            w_2ndWon AS second_won,
            w_svpt AS svpt,
            w_bpSaved AS bp_saved,
            w_bpFaced AS bp_faced,
            1 AS won     
        FROM partidos_atp_completo
        
        UNION ALL
        
        SELECT 
            loser_name AS player,
            -- 👉 Lo mismo para la parte de los perdedores
            CAST(SUBSTRING_INDEX(tourney_id, '-', 1) AS UNSIGNED) AS year_tournament,
            surface AS Superficie,
            tourney_name AS Torneo,
            tourney_level AS Nivel_Torneo,
            indoor AS Indoor_Outdoor,
            l_ace AS aces,
            l_df AS double_faults,
            minutes,
            loser_rank AS `rank`,
            loser_ht AS height,
            l_1stIn AS first_in,
            l_1stWon AS first_won,
            l_2ndWon AS second_won,
            l_svpt AS svpt,
            l_bpSaved AS bp_saved,
            l_bpFaced AS bp_faced,
            0 AS won                    
        FROM partidos_atp_completo
    ),
    Stats_Surface AS (
        SELECT
            player,
            COUNT(*) AS Partidos_Jugados,-- Incluimos el año aquí para que se arrastre a la tabla final
            year_tournament,
            (SUM(first_in)/SUM(svpt))*100 AS Efectividad_Primer_Saque, 
            (SUM(first_won)/SUM(svpt))*100 AS Puntos_Primer_Saque,
            AVG(aces) AS Promedio_Aces,
            (SUM(bp_saved)/SUM(bp_faced))*100 AS Break_Poinst_salvados,
            ((SUM(first_won)+SUM(second_won))/SUM(svpt))*100 AS Total_Saques_Ganados,
            ROUND((SUM(second_won) / (SUM(svpt) - SUM(first_in))) * 100, 2) AS Puntos_Segundo_Saque,
            ROUND(((SUM(CASE WHEN won=1 THEN 1 ELSE 0 END))/COUNT(*))*100,2) AS Porcentaje_Victorias
        FROM Tabla_Crudo
        WHERE Superficie IN ('Clay', 'Grass', 'Hard') 
        GROUP BY player, year_tournament--
        HAVING COUNT(*) > 50 
    )
    SELECT 
        Player,
        Partidos_Jugados,
        year_tournament, 
        Puntos_Segundo_Saque,
        Break_Poinst_salvados,
        Efectividad_Primer_Saque,
        Porcentaje_Victorias,
        Promedio_Aces,
        RANK() OVER(ORDER BY Porcentaje_Victorias DESC) AS Ranking
    FROM Stats_Surface
    limit 10
);

# ¿Es cierto que el promedio de aces por partido ha diminuido con la ralentización de las canchas?
# Analizar si esto es cierto 

create or replace view Slow_Wimbledon as (
with tabla_cruda as (select 
	CAST(SUBSTRING_INDEX(tourney_id, '-', 1) AS UNSIGNED) AS year_tournament,
    AVG(w_ace + l_ace) AS Promedio_Aces_Totales_Partido,
    surface as Superficie,
    sum(w_ace+l_Ace) as Total_Aces,
    tourney_name as Torneo,
    count(*) as Partidos_Jugados
from partidos_atp_completo
WHERE surface IN ('Grass')
group by CAST(SUBSTRING_INDEX(tourney_id, '-', 1) AS UNSIGNED),
 surface,
 tourney_name )
select 
	year_tournament,
    Promedio_Aces_Totales_Partido,
    Superficie,
    Torneo,
    Partidos_Jugados,
    Total_Aces/sum(Partidos_Jugados) over(partition by year_tournament) as Promedio_Year
from tabla_cruda
where Torneo in ('Wimbledon')
);

# Comparación de aces y devoluciones de segundo saque
CREATE OR REPLACE VIEW defaultdb.Features_Surface AS (
WITH Features AS (
    SELECT 
        surface AS Superficie,
        SUM(w_ace + l_ace) AS Total_Aces_Year,
        SUM(w_svpt - (w_1stWon + w_2ndWon)) AS Pts_Devolucion_Perdedor,
        SUM(l_svpt - (l_1stWon + l_2ndWon)) AS Pts_Devolucion_Ganador,
        --NUEVO: Sumamos todos los saques totales jugados en la superficie
        SUM(w_svpt + l_svpt) AS Total_Saques_Superficie, 
        COUNT(*) AS Total_partidos 
    FROM partidos_atp_completo
    WHERE w_svpt IS NOT NULL AND l_svpt IS NOT NULL -- Filtro clave para que el % sea exacto
    GROUP BY Superficie
)
SELECT 
    Superficie,
    Total_Aces_Year / Total_partidos AS Aces_Partido,
    ((Pts_Devolucion_Perdedor) + (Pts_Devolucion_Ganador)) / Total_partidos AS Pts_Devolucion_Partido,
    --Calculamos la Efectividad Real al Resto (%)
    (((Pts_Devolucion_Perdedor) + (Pts_Devolucion_Ganador)) / Total_saques_Superficie) * 100 AS Porcentaje_Efectividad_Devolucion
FROM Features
where Superficie is not null and
Superficie in ('Clay','Hard','Grass')
);

# Efectividad en devolucion por superficie (para gráfico de cajas)

create view Cajas_Surface as (
with temporal as (
select 
    CAST(SUBSTRING_INDEX(tourney_id, '-', 1) AS UNSIGNED) AS year_tournament,
    surface as Superficie, 
    tourney_name as Torneo,
	SUM(w_svpt - (w_1stWon + w_2ndWon)) AS Pts_Devolucion_Perdedor,
	SUM(l_svpt - (l_1stWon + l_2ndWon)) AS Pts_Devolucion_Ganador,   
    SUM(w_svpt + l_svpt) AS Total_Saques_Superficie
from partidos_atp_completo
group by Superficie, CAST(SUBSTRING_INDEX(tourney_id, '-', 1) AS UNSIGNED),tourney_name
)
select 
	year_tournament,
    Torneo, 
    Superficie, 
    (((Pts_Devolucion_Perdedor) + (Pts_Devolucion_Ganador)) / Total_saques_Superficie) * 100 AS Porcentaje_Efectividad_Devolucion 
from temporal
where Pts_Devolucion_Perdedor is not null
and Pts_Devolucion_Ganador is not null
and Superficie in ('Grass','Hard','Clay')
);

# View para títulos de torneos y superficies
CREATE OR REPLACE VIEW defaultdb.View_Titulos_Graficos AS (
    WITH TotalPorJugador AS (
        SELECT winner_name, COUNT(*) as titulos_totales
        FROM partidos_atp_completo
        WHERE round = 'F' AND winner_name IS NOT NULL
        GROUP BY winner_name
    )
    SELECT 
        p.winner_name AS Jugador_Campeon,
        p.surface AS Superficie,
        p.tourney_level AS Nivel_Torneo,
        COUNT(*) AS Total_Titulos
    FROM partidos_atp_completo p
    JOIN TotalPorJugador t ON p.winner_name = t.winner_name
    WHERE p.round = 'F' 
      AND p.winner_name IS NOT NULL
      AND p.surface IN ('Grass', 'Hard', 'Clay')
      AND t.titulos_totales >= 40 
    GROUP BY p.winner_name, p.surface, p.tourney_level
);

# Métricas de cabecera
CREATE OR REPLACE VIEW defaultdb.View_Metricas_Cabecera AS (
    SELECT 
        -- Cuenta todos los partidos del siglo 21
        COUNT(*) AS Total_Partidos_Global,
        
        -- Cuenta únicamente los partidos que fueron la FINAL (un título por torneo)
        SUM(CASE WHEN round = 'F' AND winner_name IS NOT NULL THEN 1 ELSE 0 END) AS Total_Titulos_Global
    FROM partidos_atp_completo
    WHERE surface IN ('Grass', 'Hard', 'Clay')
);


