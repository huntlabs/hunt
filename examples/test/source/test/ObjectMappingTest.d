module test.ObjectMappingTest;

import common;
import hunt.util.Common;

static if(CompilerHelper.isGreaterThan (2086)) {

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.ObjectUtils;
import hunt.util.UnitTest;

import std.json;
import std.datetime;

import std.conv;
import std.format;
import std.stdio;

class ObjectMappingTest {

    @Test
    void mapStructToClass() {
        Plant plant = Plant(10, "apple");
        
        Fruit f = mappingToObject!(Fruit)(plant);
        trace(f.toString());
        assert(f.getName() == plant.name);

        FruitModel fruitModel = FruitModel(12, "Apple", 9.5, 10);

        Fruit apple = mappingToObject!(Fruit)(fruitModel);
        trace(apple);
        assert(apple.getName() == fruitModel.name);
        assert(apple.number == fruitModel.number);

        Fruit peach = new Fruit("Peach", 6.5f);
        peach.description = "Red peach";

        mappingObject(fruitModel, peach);

        trace(peach);
        assert(peach.getName() == fruitModel.name);
        assert(peach.getName() == "Apple");
        assert(peach.description == "Red peach");
        assert(peach.number == fruitModel.number);
    }


    @Test
    void mapClassToStruct() {
	    Fruit apple = new Fruit("Apple", 9.5f);
        apple.number = 10;
        apple.description = "Red apple";

        Plant plant = mappingToObject!(Plant)(apple);
        trace(plant);
        assert(apple.getName() == plant.name);

        // 
        FruitModel fruitModel = mappingToObject!(FruitModel)(apple);
        trace(fruitModel);
        assert(apple.getName() == fruitModel.name);
        assert(apple.number == fruitModel.number);
        assert(fruitModel.id == 0);

        //
        fruitModel = FruitModel.init;
        fruitModel.id = 12;
        mappingObject(apple, fruitModel);
        trace(fruitModel);
        assert(apple.getName() == fruitModel.name);
        assert(apple.number == fruitModel.number);
        assert(fruitModel.id == 12);
    }

    @Test
    void mapClassToClass() {
	    Fruit apple = new Fruit("Apple", 9.5f);
        apple.number = 10;
        apple.description = "Red apple";

        Fruit apple2 = mappingToObject!(Fruit, Fruit)(apple);
        trace(apple);
        trace(apple2);
        assert(apple2.toString() == apple.toString());
    }


    @Test
    void mapStructToStruct() {
	    Fruit apple = new Fruit("Apple", 9.5f);
        apple.number = 10;
        apple.description = "Red apple";

        Plant plant = mappingToObject!(Plant)(apple);
        trace(plant);
        assert(plant.name == apple.getName());
        assert(plant.number == apple.number);

    }
}


struct FruitModel {

    int id;

    string name;
    private float price;
    int number;
}

}