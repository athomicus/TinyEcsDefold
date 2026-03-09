text
# Defold + TinyECS – Bouncing Sprites Demo

Prosty przykład użycia biblioteki [TinyECS](https://github.com/ivanquirino/defold-tiny-ecs)
w silniku [Defold](https://defold.com/).  
512 sprite'ów porusza się po ekranie i odbija od krawędzi – wszystko zarządzane przez wzorzec ECS.

---

## Co to jest ECS?

**ECS (Entity Component System)** to sposób organizacji kodu w grach:

- **Encja** – zwykła tabela Lua, np. `{ position = ..., velocity = ..., go_id = ... }`
- **Komponent** – dane przypisane do encji (pozycja, prędkość itp.)
- **System** – logika, która przetwarza encje mające odpowiednie komponenty

Zamiast pisać logikę wewnątrz każdego obiektu, piszesz systemy które działają
na **wszystkich** pasujących encjach naraz. To bardzo wydajne i łatwe do rozbudowy.

---

## Struktura projektu

<img width="184" height="395" alt="image" src="https://github.com/user-attachments/assets/ebca2013-fbb6-47e0-8337-dc6c3359e451" />


 

---

## Jak działa kod (`main.script`)

### 1. Import i stałe

```lua
local tiny = require("tinyecs.tiny")  -- wczytuje bibliotekę TinyECS
local SCREEN_W = 960                  -- szerokość ekranu
local SCREEN_H = 640                  -- wysokość ekranu
local COUNT = 512                     -- liczba obiektów do stworzenia

2. System ruchu (moveSystem)

Odpowiada za przesuwanie encji i odbijanie od krawędzi ekranu.
Działa tylko na encjach, które mają position i velocity.

lua
local moveSystem = tiny.processingSystem()
moveSystem.filter = tiny.requireAll("position", "velocity")

function moveSystem:process(e, dt)
    -- przesuń encję zgodnie z prędkością (dt = czas od ostatniej klatki)
    e.position.x = e.position.x + e.velocity.x * dt
    e.position.y = e.position.y + e.velocity.y * dt

    -- odbicie od lewej/prawej krawędzi
    if e.position.x < 0 or e.position.x > SCREEN_W then
        e.velocity.x = -e.velocity.x
        e.position.x = math.max(0, math.min(e.position.x, SCREEN_W))
    end

    -- odbicie od górnej/dolnej krawędzi
    if e.position.y < 0 or e.position.y > SCREEN_H then
        e.velocity.y = -e.velocity.y
        e.position.y = math.max(0, math.min(e.position.y, SCREEN_H))
    end
end

3. System renderowania (renderSystem)

Przenosi obliczoną pozycję z ECS na prawdziwy game object w Defoldzie.
Bez tego sprite'y stałyby w miejscu – ruch byłby tylko w pamięci.

lua
local renderSystem = tiny.processingSystem()
renderSystem.filter = tiny.requireAll("position", "go_id")

function renderSystem:process(e, dt)
    -- ustaw pozycję game objecta Defold na pozycję encji ECS
    go.set_position(e.position, e.go_id)
end

4. Inicjalizacja (init)

Tworzy świat ECS, spawn'uje 512 game objectów przez fabrykę
i rejestruje każdy jako encję z losową pozycją i prędkością.

lua
function init(self)
    math.randomseed(os.time())                        -- losowanie inne przy każdym uruchomieniu
    world = tiny.world(moveSystem, renderSystem)      -- tworzy świat i rejestruje systemy

    for i = 1, COUNT do
        local x = math.random(0, SCREEN_W)
        local y = math.random(0, SCREEN_H)

        -- tworzy sprite w Defoldzie przez fabrykę
        local go_id = factory.create("#factory", vmath.vector3(x, y, 0))

        -- tworzy encję ECS – sama tabela Lua z danymi
        local entity = {
            position = vmath.vector3(x, y, 0),
            velocity = vmath.vector3(
                math.random(-150, 150),   -- losowa prędkość pozioma
                math.random(-150, 150),   -- losowa prędkość pionowa
                0
            ),
            go_id = go_id                 -- powiązanie z game objectem Defold
        }

        tiny.addEntity(world, entity)     -- dodaje encję do świata ECS
    end
end

5. Pętla i sprzątanie

lua
function update(self, dt)
    tiny.update(world, dt)    -- co klatkę uruchamia wszystkie systemy
end

function final(self)
    tiny.clearEntities(world) -- przy zamknięciu sceny czyści encje z ECS
end                           -- game objecty Defold usuwa automatycznie

Konfiguracja game.project

Domyślny limit sprite'ów w Defoldzie to 128.
Przy 512 obiektach musisz go zwiększyć:

text
[sprite]
max_count = 512

game.project → Sprite → Max Count → 512
Wymagania

    Defold (dowolna aktualna wersja)

    TinyECS dla Defold

    prototype.go musi zawierać komponent Sprite z przypisaną teksturą

###############

for i = 1, 3 do
    local entity = { hp = math.random(30, 99) }
    tiny.addEntity(world, entity)  -- world "łapie" wskaźnik
end
..
entity_map = {}
entity_map[go_id] = entity 
tiny.addEntity(world, entity) --Dodajemy wygenerowaną encję do naszego świata TinyECS

tiny.addEntity - "trzyma" wskaznik do entity ktory normalnie po wyjsciu z petli by zniknal ale wskaznik jest wiec dalej entity sa wpamieci

PAMIĘĆ RAM
══════════════════════════════════════════════════════

  TABELA #1          TABELA #2          TABELA #3
  ┌───────────┐      ┌───────────┐      ┌───────────┐
  │ hp = 75   │      │ hp = 43   │      │ hp = 91   │
  │ damage= 2 │      │ damage= 3 │      │ damage= 1 │
  │ go_id=h1  │      │ go_id=h2  │      │ go_id=h3  │
  └─────▲─────┘      └─────▲─────┘      └─────▲─────┘
        │                  │                  │
        │                  │                  │
  ══════╪══════════════════╪══════════════════╪══════
        │   entity_map     │                  │
        │   ┌──────────────┼──────────────┐   │
        │   │ [h1] ────────┘              │   │
        └───│ [h2] ────────────────────── │───┘
            │ [h3] ──────────────────────►│
            └─────────────────────────────┘

        │   world.entities               │
        │   ┌─────────────────────────┐  │
        └──►│ [1] = TABELA #1         │  │
            │ [2] = TABELA #2 ────────┼──┘
            │ [3] = TABELA #3         │
            └─────────────────────────┘

        │   moveSystem.entities          │
        │   ┌─────────────────────────┐  │
        └──►│ [1] = TABELA #1         │  │
            │ [2] = TABELA #2 ────────┼──┘
            │ [3] = TABELA #3         │
            └─────────────────────────┘
