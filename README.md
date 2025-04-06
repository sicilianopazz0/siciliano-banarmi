# 🔫 SicilianoStudio Ban Armi

Un sistema avanzato per il ban temporaneo delle armi nel tuo server FiveM.

## ✨ Caratteristiche

- 🎯 Sistema di ban temporaneo per le armi
- ⏱️ Interfaccia con timer in tempo reale
- 💾 Salvataggio dei ban nel database
- 👮‍♂️ Comandi per staff
- 🎨 Interfaccia elegante e non invasiva

## 📋 Requisiti

- ESX Framework
- MySQL

## 🚀 Installazione

1. Scarica il file
2. Estrai la cartella `siciliano-banarmi` nella cartella `resources`
3. Importa il file `sql.sql` nel tuo database
4. Aggiungi `ensure siciliano-banarmi` nel tuo `server.cfg`
5. Riavvia il server

## 🛠️ Configurazione

Modifica il file `config.lua` per personalizzare:
- Durate dei ban
- Gruppi autorizzati (di default: admin, superadmin)
- Armi bannate

## 📜 Comandi

- `/banarmi [ID]` - Banna le armi ad un giocatore
- `/unbanarmi [ID]` - Rimuovi il ban armi ad un giocatore

## 👥 Permessi

Di default, i seguenti gruppi possono utilizzare i comandi:
- admin
- superadmin

Puoi aggiungere altri gruppi modificando il file `config.lua`

## 🤝 Supporto

Per supporto o segnalazione di bug, apri un issue su GitHub.

## 📄 Licenza

Questo progetto è sotto licenza MIT - vedi il file [LICENSE](LICENSE) per i dettagli. 