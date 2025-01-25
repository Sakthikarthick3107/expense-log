

import 'package:expense_log/models/collection.dart';
import 'package:hive/hive.dart';

class CollectionService{
  final _collectionBox = Hive.box<Collection>('collectionBox');

  List<Collection> getCollections() =>  _collectionBox.values.toList();

  bool isCollectionExist(Collection entry){
    final getCollections = _collectionBox.values.toList();
    return getCollections.any((col) => col.name.toLowerCase() == entry.name.toLowerCase());

  }

  void clear(){
    _collectionBox.clear();
  }

  int createCollection(Collection collection){
    final checkIfExist = _collectionBox.get(collection.id);
    if(checkIfExist == null ){
      if(isCollectionExist(collection)){
        return 0;
      }
      else{
        _collectionBox.put(collection.id,collection);
        return 1;
      }
    }
    else{
      if(collection.name.toLowerCase() !=  checkIfExist.name.toLowerCase()){
        if(isCollectionExist(collection)){
          return 0;
        }

      }
      _collectionBox.put(collection.id,collection);
      return 1;
    }
  }

  int deleteCollection(int id){
    _collectionBox.delete(id);
    return 1;
  }

}