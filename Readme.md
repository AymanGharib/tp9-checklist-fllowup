# TP9 - Firewall Rules using Snort and Mininet
## Lab Checklist Report

---

## Q1. Snort est-il en cours d'exécution ? En déduire son mode de fonctionnement (IDS ou IPS).

**Commande exécutée sur R1:**
```bash
ps aux | grep snort
```

**Résultat:**

![Q1 Screenshot](screenhots\q1.png)

**Explication:**

Oui, Snort est en cours d'exécution. On observe deux processus :
- PID 3268 : `/usr/sbin/snort` - Le processus principal de Snort
- PID 3842 : `grep snort` - La commande grep elle-même

**Mode de fonctionnement:** Snort fonctionne en **mode IDS (Intrusion Detection System)**. On peut le confirmer car :
- Snort génère des alertes dans `/var/log/snort/alert`
- Il ne bloque pas activement le trafic (c'est iptables qui s'en charge)
- Les paquets malveillants sont détectés mais initialement autorisés à passer

---

## Q2. Quelle interface réseau Snort surveille-t-il et pourquoi est-ce logique dans cette topologie ?

**Commande exécutée sur R1:**
```bash
cat /etc/snort/snort.conf | grep interface
```

**Résultat:**

![Q2 Screenshot](screenhots\q2.png)

**Explication:**

Snort surveille l'interface **r1-eth1**.

**Pourquoi est-ce logique ?**
- R1 agit comme routeur entre le réseau interne (où se trouve H5) et le réseau externe (où se trouve H10)
- L'interface r1-eth1 est connectée au réseau externe/Internet
- Tout le trafic entrant et sortant vers Internet passe par cette interface
- Cela permet à Snort d'inspecter tout le trafic malveillant provenant d'Internet

---

## Q3. Combien d'alertes ont été générées après le téléchargement du malware ?

**Commande exécutée sur R1:**
```bash
wc -l /var/log/snort/alert
```

**Résultat:**

![Q3 Screenshot](screenhots\q3.png)

**Explication:**

**2 alertes** ont été générées après le téléchargement du malware.

Ces alertes correspondent aux deux téléchargements du fichier `W32.Nimda.Amm.exe` effectués depuis H5 vers le serveur malveillant H10. Chaque téléchargement a déclenché une alerte Snort avec le message "Malicious Server Hit!".

---

## Q4. Quel champ de la sortie permet de confirmer que la règle DROP est réellement utilisée ? Expliquez.

**Commande exécutée sur R1:**
```bash
iptables -L FORWARD -v -n
```

**Résultat:**

![Q4 Screenshot](screenhots\q4.png)

**Explication:**

Le champ qui confirme l'utilisation de la règle DROP est : **pkts = 12 et bytes = 7840**

- **pkts (packets):** 12 paquets ont été traités par cette règle
- **bytes:** 7840 octets ont été bloqués
- **target = DROP:** L'action de la règle est bien DROP

Ces compteurs non nuls prouvent que la règle a effectivement intercepté et bloqué du trafic destiné à 209.165.202.133 sur le port TCP 6666. Si les compteurs étaient à 0, cela signifierait que la règle n'a jamais été déclenchée.

---

## Q5. Test de connectivité ICMP après blocage : Le ping est-il bloqué ? Pourquoi ?

**Commande exécutée sur H5:**
```bash
ping -c 4 209.165.202.133
```

**Résultat:**

![Q5 Screenshot](screenhots\q5.png)

**Explication:**

**Non, le ping n'est PAS bloqué.** Le ping fonctionne normalement (0% packet loss).

**Pourquoi ?**
La règle iptables ajoutée bloque uniquement :
```bash
-p tcp -d 209.165.202.133 --dport 6666 -j DROP
```

Cette règle cible spécifiquement :
- **Protocole TCP** (`-p tcp`)
- **Port de destination 6666** (`--dport 6666`)

Le ping utilise le **protocole ICMP**, pas TCP. Par conséquent, les paquets ICMP ne correspondent pas à la règle et sont autorisés à passer. Seules les connexions TCP vers le port 6666 sont bloquées.

---

## Q6. Analyse du fichier PCAP généré : Quel protocole de couche transport est observé dans la capture ?

**Commande exécutée sur H5:**
```bash
tcpdump -r nimda.download.pcap | head -n 3
```

**Résultat:**

![Q6 Screenshot](screenhots\q6.png)

**Explication:**

Le protocole de couche transport observé est **TCP**.

On peut le voir clairement dans la sortie :
- `proto TCP` apparaît dans les lignes
- Communication bidirectionnelle entre 209.165.200.235:34484 et 209.165.202.133:6666
- Flags [S] indiquent le SYN du handshake TCP

Le protocole TCP est utilisé car wget effectue une requête HTTP (qui repose sur TCP) pour télécharger le fichier malveillant depuis le serveur web nginx.

---

## Q7. Identification de la direction du trafic dans l'alerte Snort

**Basé sur la sortie de l'alerte Snort:**
```
209.165.200.235:34484 -> 209.165.202.133:6666
```

**Explication:**

- **Client (source):** 209.165.200.235 (H5) sur le port 34484
- **Serveur (destination):** 209.165.202.133 (H10) sur le port 6666

**Justification:**
- Le port source 34484 est un **port éphémère** (dynamique, > 1024), typique d'un client
- Le port destination 6666 est le **port d'écoute du serveur web** nginx
- La direction de la flèche (`->`) indique le sens du trafic : du client vers le serveur
- H5 initie la connexion pour télécharger le fichier malveillant depuis H10

---

## Q8. Quelle est la politique par défaut appliquée aux chains INPUT, OUTPUT et FORWARD ?

**Commande exécutée sur R1:**
```bash
iptables -S
```

**Résultat:**

![Q8 Screenshot](screenhots\q8.png)

**Explication:**

Les politiques par défaut sont :
- **INPUT:** ACCEPT
- **OUTPUT:** ACCEPT
- **FORWARD:** ACCEPT

**Signification:**
- Par défaut, tout le trafic est **autorisé** (ACCEPT)
- C'est une configuration permissive où seules les règles explicites de DROP bloquent le trafic
- Cette approche est moins sécurisée qu'une politique "deny by default" où tout serait bloqué sauf ce qui est explicitement autorisé
- La règle spécifique de DROP pour le port 6666 a été ajoutée manuellement à la chain FORWARD

---

## Q9. Effet d'un arrêt de Snort sur la sécurité

**Action effectuée:** Arrêter Snort (Ctrl+C dans le terminal Snort)

**Question:** Le téléchargement du fichier malveillant est-il à nouveau possible ? Pourquoi ?

**Réponse:**

**Non**, le téléchargement reste **bloqué** même après l'arrêt de Snort.

**Pourquoi ?**
- **Snort** fonctionne en mode IDS (détection uniquement) - il ne bloque pas activement le trafic
- **iptables** est le composant qui bloque réellement le trafic avec la règle DROP
- La règle iptables reste active même si Snort est arrêté
- Seule la **détection et l'enregistrement d'alertes** sont perdus, pas le blocage

**Impact:**
- ❌ Plus d'alertes générées dans `/var/log/snort/alert`
- ✅ Le trafic malveillant reste bloqué par iptables
- ⚠️ Perte de visibilité sur les tentatives d'attaque

---

## Q10. Blocage complet du serveur malveillant (tous les ports)

**Objectif:** Bloquer tout trafic TCP à destination du serveur malveillant, quel que soit le port.

**Commande à exécuter sur R1:**
```bash
# Supprimer l'ancienne règle spécifique au port 6666
iptables -D FORWARD -p tcp -d 209.165.202.133 --dport 6666 -j DROP

# Ajouter une règle bloquant tous les ports TCP
iptables -I FORWARD -p tcp -d 209.165.202.133 -j DROP
```

**Vérification:**
```bash
iptables -L FORWARD -v -n
```

**Test depuis H5:**
```bash
# Test port 6666
wget 209.165.202.133:6666/W32.Nimda.Amm.exe

# Test port 80
wget 209.165.202.133:80/index.html

# Test ping (ICMP)
ping -c 4 209.165.202.133
```

**Résultat attendu:**
- ❌ wget sur port 6666 : Connection timed out (bloqué)
- ❌ wget sur port 80 : Connection timed out (bloqué)
- ✅ ping : Successful (ICMP n'est pas TCP, donc non bloqué)

**Conclusion:**
Cette approche est **plus agressive et plus sécurisée** car elle bloque toutes les connexions TCP vers le serveur malveillant, quel que soit le port utilisé. Cela empêche l'attaquant de contourner le blocage en utilisant un autre port.

---

## Q12. Journalisation du trafic malveillant avant blocage

**Objectif:** Ajouter une règle qui journalise les tentatives d'accès au serveur malveillant avant de les bloquer.

### Configuration sur R1:

```bash
# 1. Supprimer l'ancienne règle DROP
iptables -D FORWARD -p tcp -d 209.165.202.133 --dport 6666 -j DROP

# 2. Créer une nouvelle chaîne pour la journalisation
iptables -N LOG_AND_DROP

# 3. Ajouter une règle de journalisation dans cette chaîne
iptables -A LOG_AND_DROP -j LOG --log-prefix "MALWARE_ATTEMPT: " --log-level 4

# 4. Ajouter une règle de DROP après la journalisation
iptables -A LOG_AND_DROP -j DROP

# 5. Rediriger le trafic vers le serveur malveillant vers cette chaîne
iptables -I FORWARD -p tcp -d 209.165.202.133 --dport 6666 -j LOG_AND_DROP
```

### Test depuis H5:
```bash
wget 209.165.202.133:6666/W32.Nimda.Amm.exe
```

### Affichage des logs sur R1:
```bash
tail -n 1 /var/log/messages
```

**Résultat:**

![Q12 Screenshot](screenhots\q12.png)

**Informations dans les logs:**
```
Dec 23 21:40:15 docker-desktop kernel: MALWARE_ATTEMPT: IN=eth1 OUT=eth2 SRC=209.165.200.235 DST=209.165.202.133 PROTO=TCP SPT=34484 DPT=6666
```

**Analyse:**
- **MALWARE_ATTEMPT:** Préfixe personnalisé pour identifier facilement les tentatives
- **IN=eth1:** Interface d'entrée du paquet
- **OUT=eth2:** Interface de sortie prévue
- **SRC:** Adresse IP source (H5)
- **DST:** Adresse IP destination (serveur malveillant)
- **SPT:** Port source (éphémère)
- **DPT:** Port destination (6666)

**Pourquoi est-ce utile pour l'analyste sécurité ?**
1. **Traçabilité:** Enregistrement horodaté de toutes les tentatives d'accès
2. **Analyse forensique:** Permet d'identifier les machines compromises du réseau interne
3. **Détection de patterns:** Repérer des tentatives répétées ou des comportements suspects
4. **Conformité:** Documentation des incidents pour les audits de sécurité
5. **Amélioration des règles:** Statistiques pour affiner les politiques de sécurité

---

## Q13. Quel est le rôle principal de Mininet dans ce TP ?

**Réponse:** ✅ **Créer une topologie réseau virtuelle pour les tests**

**Explication:**

Mininet permet de :
- Simuler une topologie réseau complète (routeurs R1/R4, hôtes H1-H11)
- Créer des environnements réseau isolés pour les tests de sécurité
- Éviter d'utiliser du matériel physique ou de compromettre un réseau réel
- Tester des configurations de firewall et IDS en toute sécurité

**Pourquoi les autres réponses sont incorrectes:**
- ❌ Simuler des attaques réelles : C'est Snort et les scripts qui gèrent cela
- ❌ Capturer le trafic : C'est tcpdump qui capture les paquets
- ❌ Configurer automatiquement iptables : Configuration manuelle requise
- ❌ Toutes les réponses : Seule la création de topologie est le rôle principal

---

## Q14. À quoi peut servir le fichier nimda.download.pcap pour un analyste sécurité ?

**Réponse:** ✅ **Analyser le trafic réseau et confirmer l'attaque**

**Explication:**

Le fichier PCAP permet à l'analyste de :

1. **Analyse post-incident:**
   - Examiner le contenu exact des paquets échangés
   - Identifier les patterns d'attaque

2. **Validation des alertes:**
   - Confirmer que l'alerte Snort correspond à un vrai positif
   - Vérifier le payload malveillant dans les paquets

3. **Investigation forensique:**
   - Timeline précise des événements
   - Corrélation avec d'autres logs système

4. **Formation et amélioration:**
   - Créer des signatures IDS plus précises
   - Former d'autres analystes avec des cas réels

**Pourquoi les autres réponses sont incorrectes:**
- ❌ Restaurer le fichier : PCAP contient le trafic, pas le fichier lui-même
- ❌ Mettre à jour iptables automatiquement : Nécessite une intervention manuelle
- ❌ Redémarrer Snort : Aucun lien entre PCAP et le redémarrage de Snort
- ❌ Inutile : Au contraire, c'est essentiel pour l'analyse

---

## Q15. Pourquoi Snort a-t-il généré une alerte lors du téléchargement du fichier ?

**Réponse:** ✅ **Le payload correspond à une signature malveillante**

**Explication:**

Snort fonctionne avec des **signatures** prédéfinies qui analysent le **contenu (payload)** des paquets. Dans ce cas :

1. **Analyse du payload:**
   - Snort inspecte le contenu du fichier W32.Nimda.Amm.exe en transit
   - Le payload contient des patterns caractéristiques du malware Nimda

2. **Correspondance avec signature:**
   - Règle Snort déclenchée : `[1:1000003:0] Malicious Server Hit!`
   - La signature détecte les caractéristiques du malware connu

3. **Génération d'alerte:**
   - Snort enregistre l'événement dans `/var/log/snort/alert`
   - Inclut timestamp, IPs, ports et message d'alerte

**Pourquoi les autres réponses sont incorrectes:**
- ❌ Port interdit : Le port 6666 n'est pas interdit par défaut
- ❌ IP source inconnue : Snort se base sur les signatures, pas sur les IPs
- ❌ Firewall a bloqué : Snort détecte avant qu'iptables ne bloque

**Distinction importante:**
- **Snort (IDS):** Détecte et alerte sur base du payload
- **iptables (Firewall):** Bloque sur base des headers (IP, port, protocole)

---

## Conclusion du TP

Ce TP a démontré l'utilisation complémentaire de :
- **Snort (IDS)** pour la détection des menaces
- **iptables (Firewall)** pour le blocage du trafic malveillant
- **tcpdump** pour la capture et l'analyse forensique

L'approche en couches (détection + blocage + journalisation) offre une défense en profondeur efficace contre les menaces réseau.

---

*Rapport généré pour TP9 - Firewall Rules using Snort and Mininet*