## This file contains description of the NoSQL database

### users

+ **_id**         - *Objectid*
+ **login**       - *String*
+ **password**    - *String*
+ **status**      - *String(online, offline)*
+ **sid**         - *String*
+ **created_at**  - *ISODate*

### messages

+ **_id**         - *Objectid*
+ **creator**     - *ObjectId*
+ **text**        - *String*
+ **created_at**  - *ISODate*

### units

+ **_id**         - *Objectid*
+ **name**        - *String*
+ **rank**        - *Number*
+ **move_length** - *Number*
+ **min_count**   - *Number*
+ **max_count**   - *Number*
+ **description** - *String*
+ **win_duels**   - *Object*
    + **attack**    - *Array of 'ObjectId's || String(all)*
    + **protect**   - *Array of 'ObjectId's || String(all)*
+ **created_at**  - *ISODate*

### maps

+ **_id**         - *Objectid*
+ **creator**     - *ObjectId*
+ **name**        - *String*
+ **width**       - *Number*
+ **height**      - *Number*
+ **structure**   - *Object*
    + **obst**      - *Array of 'Number's*
    + **pl1**       - *Array of 'Number's*
    + **pl2**       - *Array of 'Number's*
+ **created_at**  - *ISODate*

### armies

+ **_id**         - *Objectid*
+ **creator**     - *ObjectId*
+ **name**        - *String*
+ **units**       - *Object*
    + **unit**      - *ObjectId*
    + **count**     - *Number*
+ **created_at**  - *ISODate*

### games

+ **_id**           - *Objectid*
+ **creator**       - *ObjectId*
+ **name**          - *String*
+ **map**           - *ObjectId*
+ **army**          - *ObjectId*
+ **placement**     - *Object*
    + **pl1**         - *PlPlacement* 
    + **pl2**         - *PlPlacement* 
+ **cur_placement** - *Object*
    + **pl1**         - *PlPlacement* 
    + **pl2**         - *PlPlacement* 
+ **moves**         - *PlPlacement*
    + **pl1**         - *PlMove*
    + **pl2**         - *PlMove*
+ **created_at**    - *ISODate*

### tacktics

+ **_id**           - *Objectid*
+ **creator**       - *ObjectId*
+ **name**          - *String*
+ **map**           - *ObjectId*
+ **army**          - *ObjectId*
+ **placement**     - *Object*
    + **pl1**         - *PlPlacement* 
    + **pl2**         - *PlPlacement* 
+ **created_at**    - *ISODate*

#### Declarated special types

+ *PlPlacement*     - *Object*
    + **pos**         - *Number*    
    + **unit**        - *ObjectId*
+ *PlMove*          - *Array of 'Object's*
    + **pos_from**    - *Number*
    + **pos_to**      - *Number*
    + **created_at**  - *Number*
    
