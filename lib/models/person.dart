class Person {
  final String id;
  String name;

  Person({
    required this.id,
    required this.name,
  });

  Map<String,dynamic> toJson()=> {
    'id':id,
    'name':name,
  };

  factory Person.fromJson(Map<String,dynamic> j)=>
      Person(
        id:j['id'],
        name:j['name'],
      );
}