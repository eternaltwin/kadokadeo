/*
CUSTOMIZED ARRAY BY EXTENDING BUILT-IN CLASS
*/

class CArray extends Array {
    DeleteObject(objectToDelete) { // Delete "objectToDelete" from array
        return this.filter((obj) => !Object.is(obj, objectToDelete));
    }
}