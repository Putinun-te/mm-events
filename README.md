How to use:

Start app stack (no tests)
```docker compose up -d```
<br />
Run tests on demand
```docker compose run --rm backend-tests```
<br />
Or enable tests profile
```docker compose --profile tests up backend-tests```
<br />

Options to shut down:
Stop containers (keep them for quick restart)
```run docker compose stop```
<br />
Stop and remove containers + network
```run docker compose down```
<br />
Also remove DB volume (wipe data): 
```run docker compose down -v (or remove the named volume after docker volume ls)```
<br />
Stop specific services only: 
```run docker compose stop backend frontend```
<br />
If running locally with mvn spring-boot:run: press Ctrl+C in that terminal
