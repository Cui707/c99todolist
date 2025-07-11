import 'package:flutter/material.dart';
import 'package:c99todolist/todo_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'C99 Todo List App',
      theme: ThemeData(
        primarySwatch: Colors.grey, // 主题颜色设为灰色
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todos = [];
  final TextEditingController _textFieldController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();

  List<String> _categories = ['所有待办'];
  String _currentCategory = '所有待办';

  final TextEditingController _categoryFieldController = TextEditingController();

  List<TodoItem> get _filteredTodos {
    if (_currentCategory == '所有待办') {
      return _todos;
    } else {
      return _todos.where((todo) => todo.category == _currentCategory).toList();
    }
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    _textFieldFocusNode.dispose();
    _categoryFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的待办事项 (${_currentCategory})'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _resetCompletedTodos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('重置已完成'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _removeAllTodos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('删除全部'),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/cyxphoto1.png'), // 替换为你的图片路径
                  fit: BoxFit.cover, // 根据需要调整图片适应方式（例如：cover, fitWidth, fitHeight）
                ),
              ),
              child: Center(
                child: Text(
                  '待办分类',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                   ),
                ),
              ),
            ),
            for (var category in _categories)
              ListTile(
                title: Text(
                  category,
                  style: TextStyle(
                    fontWeight: _currentCategory == category ? FontWeight.bold : FontWeight.normal,
                    color: _currentCategory == category ? Theme.of(context).primaryColor : null,
                  ),
                ),
                selected: _currentCategory == category,
                onTap: () {
                  setState(() {
                    _currentCategory = category;
                  });
                  Navigator.pop(context);
                },
                trailing: category != '所有待办'
                    ? PopupMenuButton<String>(
                        onSelected: (String result) {
                          if (result == 'rename') {
                            _showRenameCategoryDialog(category);
                          } else if (result == 'delete') {
                            _showDeleteCategoryDialog(category);
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Text('重命名'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('删除'),
                          ),
                        ],
                      )
                    : null,
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('添加新分类'),
              onTap: () {
                Navigator.pop(context);
                _showAddCategoryDialog();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _textFieldController,
              focusNode: _textFieldFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '添加新的待办事项',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _addTodoItem(_textFieldController.text);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _addTodoItem(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  color: todo.isCompleted ? Colors.grey[200] : null,
                  child: GestureDetector(
                    onSecondaryTapDown: (details) {
                      _showTodoContextMenu(context, details.globalPosition, todo); 
                    },
                    child: ListTile(
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (bool? newValue) {
                          _toggleTodoStatus(index, newValue ?? false);
                        },
                      ),
                      title: Text(
                        todo.task,
                        style: TextStyle(
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _removeTodoItem(index);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addTodoItem(String task) {
    if (task.isNotEmpty) {
      setState(() {
        _todos.add(TodoItem(task: task, category: _currentCategory));
        _textFieldController.clear();
      });
      _textFieldFocusNode.requestFocus();
    }
  }

  // 删除待办事项的方法
  void _removeTodoItem(int index) {
    setState(() {
      // 修正：从 _filteredTodos 获取要删除的待办事项，然后从 _todos 中移除它
      final todoToRemove = _filteredTodos[index];
      _todos.removeWhere((todo) => todo == todoToRemove);

      // 检查“未分类”分类是否还需要存在
      // 如果“未分类”分类被删除，但仍然有待办事项属于它，则重新添加
      if (!_categories.contains('未分类') && _todos.any((todo) => todo.category == '未分类')) {
        _categories.add('未分类');
        _categories.sort();
        _categories.remove('所有待办');
        _categories.insert(0, '所有待办');
      }
    });
  }

  void _toggleTodoStatus(int index, bool newValue) {
    setState(() {
      _filteredTodos[index].isCompleted = newValue;
    });
  }

  void _showAddCategoryDialog() {
    _categoryFieldController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加新分类'),
          content: TextField(
            controller: _categoryFieldController,
            decoration: const InputDecoration(hintText: "分类名称"),
            autofocus: true,
            onSubmitted: (value) {
              _addCategory(_categoryFieldController.text);
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('添加'),
              onPressed: () {
                _addCategory(_categoryFieldController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addCategory(String newCategory) {
    newCategory = newCategory.trim();
    if (newCategory.isNotEmpty && !_categories.contains(newCategory)) {
      setState(() {
        _categories.add(newCategory);
        _categories.sort();
        _categories.remove('所有待办');
        _categories.insert(0, '所有待办');
      });
    }
  }

  void _showRenameCategoryDialog(String oldCategory) {
    _categoryFieldController.text = oldCategory;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重命名分类'),
          content: TextField(
            controller: _categoryFieldController,
            decoration: const InputDecoration(hintText: "新分类名称"),
            autofocus: true,
            onSubmitted: (value) {
              _renameCategory(oldCategory, _categoryFieldController.text);
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('重命名'),
              onPressed: () {
                _renameCategory(oldCategory, _categoryFieldController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _renameCategory(String oldCategory, String newCategory) {
    newCategory = newCategory.trim();
    if (newCategory.isNotEmpty && oldCategory != '所有待办' && oldCategory != newCategory && !_categories.contains(newCategory)) {
      setState(() {
        int index = _categories.indexOf(oldCategory);
        if (index != -1) {
          _categories[index] = newCategory;
        }
        _categories.sort();
        _categories.remove('所有待办');
        _categories.insert(0, '所有待办');

        for (var todo in _todos) {
          if (todo.category == oldCategory) {
            todo.category = newCategory;
          }
        }

        if (_currentCategory == oldCategory) {
          _currentCategory = newCategory;
        }
      });
    }
  }

  void _showTodoCategoryMenu(BuildContext context, Offset position, TodoItem todo) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        MediaQuery.of(context).size.width - position.dx,
        MediaQuery.of(context).size.height - position.dy,
      ),
      items: _categories.map((category) {
        return PopupMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
    ).then((selectedCategory) {
      if (selectedCategory != null && selectedCategory != todo.category) {
        setState(() {
          todo.category = selectedCategory;
        });
      }
    });
  }

  void _showDeleteCategoryDialog(String categoryToDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除分类'),
          content: Text('您确定要删除分类 "$categoryToDelete" 吗？此操作将把该分类下的所有待办事项归为“未分类”。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
              onPressed: () {
                _deleteCategory(categoryToDelete);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(String categoryToDelete) {
    if (categoryToDelete != '所有待办') {
      setState(() {
        _categories.remove(categoryToDelete);

        for (var todo in _todos) {
          if (todo.category == categoryToDelete) {
            todo.category = '未分类';
          }
        }

        if (_currentCategory == categoryToDelete) {
          _currentCategory = '所有待办';
        }

        if (!_categories.contains('未分类') && _todos.any((todo) => todo.category == '未分类')) {
          _categories.add('未分类');
          _categories.sort();
          _categories.remove('所有待办');
          _categories.insert(0, '所有待办');
        }
      });
    }
  }

  void _resetCompletedTodos() {
    setState(() {
      if (_currentCategory == '所有待办') {
        for (var todo in _todos) {
          todo.isCompleted = false;
        }
      } else {
        for (var todo in _todos) {
          if (todo.category == _currentCategory && todo.isCompleted) {
            todo.isCompleted = false;
          }
        }
      }
    });
  }

  // 显示待办事项上下文菜单（包含编辑和分类）
  void _showTodoContextMenu(BuildContext context, Offset position, TodoItem todo) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        MediaQuery.of(context).size.width - position.dx,
        MediaQuery.of(context).size.height - position.dy,
      ),
      items: [
        // 编辑选项
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('编辑'),
        ),
        const PopupMenuDivider(), // 分割线
        // 分类选项
        ..._categories.map((category) { // 使用 spread operator 将分类列表展开
          return PopupMenuItem<String>(
            value: category,
            child: Text('移至 "$category"'), // 更改提示，更明确是移动
          );
        }).toList(),
      ],
    ).then((selectedOption) {
      if (selectedOption != null) {
        if (selectedOption == 'edit') {
          _showEditTodoDialog(todo); // 调用编辑对话框
        } else if (selectedOption != todo.category) {
          // 如果选择的是分类，并且与当前分类不同
          setState(() {
            todo.category = selectedOption; // 更新待办事项的分类
          });
        }
      }
    });
  }

  void _showEditTodoDialog(TodoItem todo) {
    _textFieldController.text = todo.task; // 预填当前待办内容
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('编辑待办事项'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: "修改待办内容"),
            autofocus: true,
            onSubmitted: (value) {
              _editTodoItem(todo, _textFieldController.text);
              Navigator.of(context).pop(); // 关闭对话框
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                _textFieldController.clear(); // 取消时清空控制器
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('保存'),
              onPressed: () {
                _editTodoItem(todo, _textFieldController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // 对话框关闭后，清空输入框，防止影响添加新待办
      _textFieldController.clear();
    });
  }



  // 执行编辑待办事项逻辑
  void _editTodoItem(TodoItem todo, String newTask) {
    newTask = newTask.trim();
    if (newTask.isNotEmpty) {
      setState(() {
        todo.task = newTask; // 更新待办事项的文本内容
      });
    }
  }

  void _removeAllTodos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除当前分类下所有待办事项？'),
          content: const Text('此操作不可撤销，您确定要删除当前分类下所有待办事项吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('删除'),
              onPressed: () {
                setState(() {
                  if (_currentCategory == '所有待办') {
                    _todos.clear();
                  } else {
                    _todos.removeWhere((todo) => todo.category == _currentCategory);
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}