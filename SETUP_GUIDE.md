# SageFit - Guida Setup Locale (Mac Apple Silicon)

## Requisiti
- Docker Desktop per Mac installato e in esecuzione
- Python 3 installato via Homebrew (`/opt/homebrew/bin/python3`)
- VS Code (opzionale ma consigliato)

---

## 1. Abilitare Rosetta in Docker Desktop (una volta sola)
Docker Desktop → Settings → General → spunta **"Use Rosetta for x86_64/amd64 emulation on Apple Silicon"** → Apply & Restart

---

## 2. Avviare il container Oracle XE (prima volta)

```bash
docker run -d \
  --name oracle-xe \
  -p 1521:1521 \
  -e ORACLE_PASSWORD=password123 \
  --platform linux/amd64 \
  --restart always \
  gvenzl/oracle-xe:21-slim
```

Aspetta che il DB sia pronto (~2-3 minuti):
```bash
docker logs -f oracle-xe
# attendi: DATABASE IS READY TO USE!
# poi Ctrl+C per uscire dai log
```

> Grazie a `--restart always`, dalla seconda volta basterà aprire Docker Desktop e il container parte da solo.

---

## 3. Caricare lo schema e i dati (solo la prima volta)

Copia gli script nel container:
```bash
docker cp Exam/script.sql oracle-xe:/tmp/script.sql
docker cp Exam/index.sql oracle-xe:/tmp/index.sql
```

Connettiti a Oracle:
```bash
docker exec -it oracle-xe sqlplus system/password123@//localhost:1521/XE
```

Dentro SQLPlus, esegui lo script principale (crea schema, trigger, indici e popola il DB):
```sql
@/tmp/script.sql
```

Output atteso al termine:
- Tutte le procedure/trigger create senza errori
- `PL/SQL procedure successfully completed` (SchemaCreation + PopulateDatabase)
- Tre errori **intenzionali** nel test finale: duplicato unique, trigger capacità team, trigger capacità location

Poi esci da SQLPlus:
```sql
EXIT
```

---

## 4. Avviare la Web App Flask

Dalla root del progetto, crea il virtual environment (solo la prima volta):
```bash
cd Exam/webApp
python3 -m venv venv
```

Attiva il virtual environment e installa le dipendenze (solo la prima volta):
```bash
source venv/bin/activate
pip install flask oracledb
```

Avvia l'app:
```bash
python3 app.py
```

Apri il browser su: [http://localhost:5000](http://localhost:5000)

---

## Dalla seconda volta in poi

1. Apri Docker Desktop (il container Oracle parte automaticamente)
2. In un terminale:
```bash
cd Exam/webApp
source venv/bin/activate
python3 app.py
```
3. Apri [http://localhost:5000](http://localhost:5000)

---

## 5. Estensioni VS Code consigliate
- **Oracle Developer Tools for VS Code** (oracle.oracledevtools) — per gestire il DB direttamente dall'editor
- **Python** (ms-python.python)

Configurazione connessione in Oracle Developer Tools:
- Host: `localhost`
- Port: `1521`
- Service Name: `XE`
- User: `system`
- Password: `password123`

---

## Note
- Il SID/Service Name è `XE` (maiuscolo)
- La password di sistema è `password123` (impostata con `-e ORACLE_PASSWORD`)
- Per fermare il container: `docker stop oracle-xe`
- Per riavviarlo manualmente: `docker start oracle-xe`
- Il virtual environment (`venv/`) è dentro `Exam/webApp/` — non va committato su git
