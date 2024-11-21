/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as (
      select artist.artist_id , artist.name as artist_name , 
	  sum(invoice_line.unit_price * invoice_line.quantity) as total_sales
	  from invoice_line
	  join track on track.track_id = invoice_line.track_id 
	  join album on album.album_id = track.album_id
	  join artist on artist.artist_id = album.artist_id
	  group by artist.artist_id
	  order by total_sales desc
	  limit 1
)
select c.customer_id , c.first_name , c.last_name , bsa.artist_name ,
sum(il.unit_price * il.quantity) as amount_spent
from invoice as i
join customer as c on c.customer_id = i.customer_id
join invoice_line as il on i.invoice_id = il.invoice_id
join track as t on t.track_id = il.track_id
join album as alb on alb.album_id = t.album_id
join best_selling_artist as bsa on bsa.artist_id = alb.artist_id
group by c.customer_id ,  c.first_name , c.last_name , bsa.artist_name
order by amount_spent desc;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */
with popular_genre as (
      select count(invoice_line.quantity) as purchases , customer.country , genre.name , genre.genre_id ,
	  row_number() over (partition by customer.country order by count(invoice_line.quantity) desc ) as rowno
	  from invoice_line
	  join invoice on invoice_line.invoice_id = invoice.invoice_id
	  join customer on customer.customer_id = invoice.customer_id
	  join track on track.track_id = invoice_line.track_id
	  join genre on genre.genre_id = track.genre_id
	  group by customer.country , genre.name , genre.genre_id
	  order by customer.country asc , purchases desc	  
)
select * from popular_genre where rowno <= 1

/* Method 2: Using Recursive */

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using Recursive */	
WITH RECURSIVE 
	    customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	    country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;


/* Method 2: Using CTE */
with customer_with_country as (
      SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending ,
	  row_number() over (partition by billing_country order by sum(total) desc ) as rowno
	  from invoice
	  join customer on customer.customer_id = invoice.customer_id
	  group by customer.customer_id , first_name , last_name , billing_country
	  order by billing_country asc , total_spending desc	  
)
select * from customer_with_country where rowno <= 1