#Stratego

Данный проект является учебным и представляет собой онлайновую реализацию настольной игры **Stratego**.
Правила игры можно посмотреть [тут](http://en.wikipedia.org/wiki/Stratego).

## Описание основных возможностей

Игра расчитана на двух человек.
Чтобы начать игру необходимо пройти регистрацию.


Помимо собственно игрового процесса, в игре имеется ряд редакторов:

+ Редактор карт
+ Редактор армий
+ Редактор тактик (в разработке)

Т.е. все из вышеперечисленного можно создавать, редактировать, удалять.
Причем последние два дейтсвия может осущетвить только непосредственно создатель.


Особенности создания/редактирования карт:

+ Карта должна быть размером не менее 3 на 3
+ Количества клеток для двух игроков должны совпадать
+ Должно быть по крайне мере две клетки для игрока

Особенности создания/редактирования армий:

+ В армии должен быть один, и только один флаг
+ В армии должен быть хотя бы один активный юнит
+ Если армия содержит бомбу, то в ней обязательно должен быть сапер

## Детали реализации

### Инструменты разработки:

**BackEnd**

* [ruby 1.9.3p0](https://github.com/ruby/ruby)
* [em-websocket](https://github.com/igrigorik/em-websocket)
* [Sinatra](https://github.com/sinatra/sinatra)
* [MongoDB](https://github.com/mongodb/mongo)
* [mongo-ruby-driver](https://github.com/mongodb/mongo-ruby-driver)
    

**FrontEnd**

* [CoffeeScript](https://github.com/jashkenas/coffee-script)
* [jQuery](https://github.com/jquery/jquery)
* [jQueryUI](https://github.com/jquery/jquery-ui)
* [Spine](https://github.com/maccman/spine)
* [Underscore.js](https://github.com/documentcloud/underscore)
* [web-socket-js](https://github.com/gimite/web-socket-js)
* [Haml](https://github.com/nex3/haml)
* [Sass](https://github.com/nex3/sass)
* [Compass](https://github.com/chriseppstein/compass)
* [Bootstrap](https://github.com/twitter/bootstrap)

### Краткое описание основных принципов разработки

Все взаимодествие клиента и сервера осуществляется через [websoket'ы](http://dev.w3.org/html5/websockets/).
Для хранения данных на сервере используется документо-ориентированная СУБД *MongoDB*.


Программный код на языке ruby по большей части выдержан в [следующем стиле](https://github.com/bbatsov/ruby-style-guide)


При разработке клиента основной упор ориентирован на легкость дальнейшей поддержки клиентского кода.
Поэтому было принято решение использовать MVC фреймворк *Spine*.
Для хранения информации о сессии клиента, а так же о некоторых ресурсов игры, используется [SessionStorage](http://dev.w3.org/html5/webstorage/)

## Установка и использование:
    
    $ git clone git@github.com:VasayXTX/Stratego.git
    $ cd Stratego/
    $ bundle install
    
Для очистки базы данных:

    $ rake clean
    
Для очистки базы данных и создание основных ресурсов:

    $ rake seed
    
Для запуска сервера:

    $ ruby app.rb
    