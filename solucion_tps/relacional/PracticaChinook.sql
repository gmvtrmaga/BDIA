-- 1 Selecciona todos los registros de la tabla Albums.
SELECT * FROM album

-- 2 Selecciona todos los géneros únicos de la tabla Genres.
SELECT * FROM genre

-- 3 Cuenta el número de pistas por género.
SELECT genre.name, COUNT(*) FROM track 
	INNER JOIN genre ON track.genre_id=genre.genre_id 
	GROUP BY genre.name

-- 4 Encuentra la longitud total (en milisegundos) de todas las pistas para cada álbum.
SELECT album.title, SUM(track.milliseconds) FROM track 
	INNER JOIN album ON track.album_id=album.album_id 
	GROUP BY album.title

-- 5 Lista los 10 álbumes con más pistas.
SELECT album.title, COUNT(*) FROM track 
	INNER JOIN album ON track.album_id=album.album_id 
	GROUP BY album.title ORDER BY COUNT(*) DESC LIMIT 10

-- 6 Encuentra la longitud promedio de la pista para cada género.
SELECT genre.name, AVG(track.milliseconds) FROM track 
	INNER JOIN genre ON track.genre_id=genre.genre_id 
	GROUP BY genre.name

-- 7 Para cada cliente, encuentra la cantidad total que han gastado.
-- ASUMIMOS QUE EL GASTO DEL INVOICE ESTÁ BIEN CALCULADO.
-- SI NO HABRÍA QUE HACER INNER JOIN ENTRE TRACK,INVOICE_LINE, INVOICE Y CUSTOMER PARA CAlCULARLO
SELECT customer.customer_id, SUM(invoice.total) FROM invoice 
	INNER JOIN customer ON invoice.customer_id=customer.customer_id 
	GROUP BY customer.customer_id

-- 8 Para cada país, encuentra la cantidad total gastada por los clientes.
SELECT customer.country, SUM(invoice.total) FROM invoice 
	INNER JOIN customer ON invoice.customer_id=customer.customer_id 
	GROUP BY customer.country

-- 9 Clasifica a los clientes en cada país por la cantidad total que han gastado.
SELECT customer.country, customer.customer_id, SUM(invoice.total) FROM invoice 
	INNER JOIN customer ON invoice.customer_id=customer.customer_id 
	GROUP BY customer.country, customer.customer_id
	ORDER BY customer.country, SUM(invoice.total) DESC

-- 10 Para cada artista, encuentra el álbum con más pistas y clasifica a los artistas por este número.
SELECT artist.name, subquery.title, subquery.num_tracks
	FROM 
	(
		SELECT album.artist_id, 
				album.title, 
				COUNT(*) as num_tracks, 
				RANK() OVER (
					PARTITION BY album.artist_id ORDER BY COUNT(*) DESC
				) AS num_tracks_rank 
		FROM track
		INNER JOIN album ON album.album_id = track.album_id
		GROUP BY album.title, album.artist_id
	) AS subquery
	INNER JOIN artist ON artist.artist_id=subquery.artist_id
	WHERE subquery.num_tracks_rank = 1
	ORDER BY subquery.num_tracks DESC

-- 11 Selecciona todas las pistas que tienen la palabra "love" en su título.
SELECT track.name FROM track
	WHERE track.name ILIKE ('%love%')

-- 12 Selecciona a todos los clientes cuyo primer nombre comienza con 'A'.
SELECT customer_id, first_name FROM customer
	WHERE first_name ILIKE ('A%')

-- 13 Calcula el porcentaje del total de la factura que representa cada factura.
SELECT 
	invoice.invoice_id, 
	invoice_line.invoice_line_id, 
	invoice_line.unit_price, 
	invoice_line.quantity, 
	ROUND((invoice_line.unit_price * invoice_line.quantity / invoice.total) * 100, 3) AS total_percentage
	FROM invoice_line
	INNER JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	ORDER BY invoice.invoice_id
	
-- 14 Calcula el porcentaje de pistas que representa cada género.
SELECT 
	genre.name, 
	COUNT(genre.name),
	ROUND((COUNT(genre.name) * 100.0 / (SELECT COUNT(*) FROM track)), 3) AS percentage
	FROM track 
	INNER JOIN genre ON track.genre_id=genre.genre_id 
	GROUP BY genre.name
	ORDER BY percentage DESC

-- 15 Para cada cliente, compara su gasto total con el del cliente que gastó más.
SELECT 
	customer.customer_id,
	SUM(invoice.total),
	MAX(SUM(invoice.total)) OVER () AS max_spent,
	ROUND((SUM(invoice.total) / MAX(SUM(invoice.total)) OVER ()) * 100, 3) AS percentage_of_max_spent
	FROM invoice 
	INNER JOIN customer ON invoice.customer_id=customer.customer_id 
	GROUP BY customer.customer_id
	ORDER BY SUM(invoice.total) DESC

-- 16 Para cada factura, calcula la diferencia en el gasto total entre ella y la factura anterior.
SELECT 
	invoice.invoice_id,
	invoice.total,
	aux.total AS previous_total,
	invoice.total - aux.total AS difference,
	ROUND(invoice.total / aux.total * 100, 3) AS percentage_of_previous
	FROM invoice 
	INNER JOIN invoice AS aux ON invoice.invoice_id=aux.invoice_id + 1

-- 17 Para cada factura, calcula la diferencia en el gasto total entre ella y la próxima factura.
SELECT 
	invoice.invoice_id,
	invoice.total,
	aux.total AS previous_total,
	invoice.total - aux.total AS difference,
	ROUND(invoice.total / aux.total * 100, 3) AS percentage_of_previous
	FROM invoice 
	INNER JOIN invoice AS aux ON invoice.invoice_id=aux.invoice_id - 1

-- 18 Encuentra al artista con el mayor número de pistas para cada género.
SELECT aux.genre_name, aux.artist_name, aux.num_tracks FROM 
(
	SELECT 
		genre.name AS genre_name, 
		artist.name AS artist_name, 
		COUNT(*) AS num_tracks,
        RANK() OVER (PARTITION BY genre.name ORDER BY COUNT(*) DESC) AS num_tracks_rank
	FROM track 
	INNER JOIN genre ON track.genre_id=genre.genre_id
	INNER JOIN album ON album.album_id=track.album_id
	INNER JOIN artist ON artist.artist_id=album.artist_id
	GROUP BY genre.name, artist.name
) AS aux
WHERE num_tracks_rank = 1

-- 19 Compara el total de la última factura de cada cliente con el total de su factura anterior.
SELECT 
	aux1.customer_id,
	aux1.invoice_id, 
	aux2.invoice_id, 
	aux1.total as last_total, 
	aux2.total as previous_total,
	aux1.total - aux2.total AS difference,
	ROUND(aux1.total / aux2.total * 100, 3) AS percentage_of_previous
FROM (
	-- OBTENER ULTIMA FACTURA DE CADA CLIENTE
	SELECT invoice.customer_id, invoice.invoice_id, invoice.total
	FROM invoice
	INNER JOIN (
		SELECT invoice.customer_id, MAX(invoice.invoice_id) AS last_invoice_id
		FROM invoice
		GROUP BY invoice.customer_id
	) AS aux3
	ON aux3.last_invoice_id = invoice.invoice_id
) AS aux1
INNER JOIN
(
	-- OBTENER PENULTIMA FACTURA DE CADA CLIENTE
	SELECT  aux4.customer_id, aux4.invoice_id, aux4.total
	FROM (
	        SELECT 
	            customer_id, 
	            invoice_id,
				total,
	            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY invoice_date DESC) AS rn
	        FROM 
	            invoice
	 ) AS aux4
	WHERE aux4.rn = 2
) AS aux2
	ON aux1.customer_id = aux2.customer_id
ORDER BY aux1.customer_id

-- 20 Encuentra cuántas pistas de más de 3 minutos tiene cada álbum.
SELECT album.title, COUNT (*) FROM album
INNER JOIN 
	(
		SELECT * FROM public.track
		WHERE milliseconds > 180000
	)AS aux ON aux.album_id = album.album_id
GROUP BY album.title
