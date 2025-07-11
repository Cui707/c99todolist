class TodoItem {
  String task;
  bool isCompleted;
  String category;
  
  TodoItem({required this.task, this.isCompleted = false, this.category = '未分类'});
}