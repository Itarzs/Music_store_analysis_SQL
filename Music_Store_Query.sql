-- Sample data

select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;

/* Question Set 1 – SIMPLE */

-- 1. Who is the senior most employee based on job title?
select concat(last_name,' ',first_name) name, title
from employee
order by levels desc;

-- Which countries have the most Invoices? 
select count(invoice_id) invoice_count, billing_country
from invoice
group by billing_country
order by invoice_count desc;

-- What are top 3 values of total invoice? 
select total
from invoice
order by 1 desc;

/* Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city, round (sum(total), 2) sum_total
from invoice
group by billing_city
order by 2 desc
limit 1;

/* Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money */

select concat(c.first_name,' ', c.last_name) name, round(sum(i.total),2) sum_total
from invoice i
join customer c 
on i.customer_id = c.customer_id
group by 1
order by 2 desc
limit 1;

/* Question Set 2 – Moderate */

/* 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A  */
select distinct c.first_name, c.last_name, g.name, c.email
	from customer c
	join invoice i on c.city = i.billing_city
	join invoice_line il on i.invoice_id = il.invoice_id
	join track t on t.track_id = il.track_id
	join genre g on t.genre_id = g.genre_id
where g.name = 'Rock'
order by c.email asc;

-- METHOD 2
select  c.first_name, c.last_name, g.name, c.email
	from customer c
	join invoice i on c.city = i.billing_city
	join invoice_line il on i.invoice_id = il.invoice_id
	join track t on t.track_id = il.track_id
	join genre g on t.genre_id = g.genre_id
group by 1, 2, 3, 4
having g.name = 'Rock'
order by c.email asc;

/* 2. Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands */

select a.name, count(t.track_id) TrackID_count, g.name
from artist a
	join album al on a.artist_id = al.artist_id
	join track t on al.album_id = t.album_id
	join genre g on t.genre_id = g.genre_id
group by 1,3
having g.name = 'Rock'
order by 2 desc
limit 10;

/* Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first */

select name, milliseconds 
from track
where milliseconds > (select avg(milliseconds)
					 from track )
order by 2 desc;

-- METHOD 2--

with cte as (
	select name, milliseconds 
	from track
)
select name , milliseconds 
from cte 
where milliseconds > (select avg(milliseconds)
					 from cte )
order by 2 desc;

/* Question Set 3 – Advance */

/* Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1, 2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres */

with top_genre (name, country, total_purchase) as (
	select g.name, i.billing_country, count(il.quantity)  count_quantity
	from invoice i
	join invoice_line il on i.invoice_id = il.invoice_id
	join track t on t.track_id = il.track_id
	join genre g on t.genre_id = g.genre_id
	group by 1,2
	order by 3 desc
)
select name, country, total_purchase, 
row_number() over (partition by country order by total_purchase desc) AS RowNum
from top_genre;


/* Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC
	)
	SELECT * FROM Customter_with_country WHERE RowNo <= 1
