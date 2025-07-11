class TodoItem {
  String task;
  bool isCompleted;
  String category;

  TodoItem({required this.task, this.isCompleted = false, this.category = '未分类'});

  // 新增：将 TodoItem 对象转换为 JSON 格式的 Map
  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'isCompleted': isCompleted,
      'category': category,
    };
  }

  // 新增：从 JSON 格式的 Map 创建 TodoItem 对象
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      task: json['task'] as String,
      isCompleted: json['isCompleted'] as bool,
      category: json['category'] as String,
    );
  }
}