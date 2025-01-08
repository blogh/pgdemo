# TTL et  loop_wait

```default
boucle 1 |---------------------- TTL ----------------------.
boucle 2 |                |---------------------- TTL ----------------------.
boucle 3 |                                 |---------------------- TTL ------…
         0----------------1----------------2---------------3----------->
                                  loop_wait
```

# Si pb combien de temps on a ?

```default
boucle 1 |---------------------- TTL ----------------------.
         |------------------- WDT ----------------.<~ (1) ~>
boucle 2 |                |~ ~ ~ ~ ~ (2) ~ ~ ~ ~ ~>
         0----------------1----------------2---------------3----------->
                                  loop_wait

(1) =~ safety_margin
(2) =~ TTL - loop_wait - safety_margin = 30 - 10 - 5 = 15s
```

# Cas d'incident 1 : DCS hs

```default
boucle 1 |---------------------- TTL ----------------------.
         |------------------- WDT ----------------.
boucle 2 |                |~ ~ ~ (1) ~ ~ ~ ><~(2)~>
         0----------------1----------------2---------------3----------->
                                  loop_wait

(1) retry_timeout
(2) temps de demote = WDT - loop_wait - retry_timeout  = 25 - 10 - 10 = 5s
```

# Cas d'incident 2 : DCS lent

```default
boucle 1 |---------------------- TTL ----------------------.
         |<~ ~ (1) ~ ~>------------------- WDT ----------------.
         |                                                 <(2)>
         0----------------1----------------2---------------3----------->
                                  loop_wait

(1) gel > safety_margin
(2) gel + WDT > TTL, le watchdog expire après le TTL
```

* risque de split brain
* risque assez faible on a 2 boucles pour relancer TTL / WDT

# Contournement

safety_margin = -1 => WDT = TTL / 2

* équivalent a une safety margin de 15s (safety_margin = TTL - WDT = 30 - 15)
* [Graph 2] si pg cb de tps pr demote = ttl - loop_wait - safety_margin = 30 - 10 - 15 = 5s
  - c'est plus court
* [Graph 4] plus de risque avec le cas de l'incident 2
* [Graph 3] temps de démote pour incident 1 = WDT - loop_wait - retry_timeout = 15 - 10 - 10 = -5s
  - le WD se déclenche avant
  - pour aider:
    * augenter TTL pour augmenter WDT: failover plus lent
    * diminuer loop_wait: activité CPU et acces DCS plus fréquent: patroni plus sensible au pb de ressources
    * diminuer retry_timeout: moins de temps pour terminer les opérations longues: système plus senseible


