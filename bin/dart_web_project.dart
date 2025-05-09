import 'dart:convert';
import 'dart:io';

class Order {
  String item;
  String itemName;
  double price;
  String currency;
  int quantity;

  Order({
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      item: json['Item'],
      itemName: json['ItemName'],
      price: (json['Price'] is int) ? (json['Price'] as int).toDouble() : json['Price'],
      currency: json['Currency'],
      quantity: json['Quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Item': item,
      'ItemName': itemName,
      'Price': price,
      'Currency': currency,
      'Quantity': quantity,
    };
  }
}

void main() async {
  const filePath = 'order.json';
  List<Order> orders = [];

  final file = File(filePath);
  if (!await file.exists()) {
    final defaultData = [
      {
        "Item": "A1000",
        "ItemName": "Iphone 15",
        "Price": 1200,
        "Currency": "USD",
        "Quantity": 1
      },
      {
        "Item": "A1001",
        "ItemName": "Iphone 16",
        "Price": 1500,
        "Currency": "USD",
        "Quantity": 1
      }
    ];
    await file.writeAsString(jsonEncode(defaultData));
  }

  final jsonString = await file.readAsString();
  final jsonData = jsonDecode(jsonString) as List;
  orders = jsonData.map((order) => Order.fromJson(order)).toList();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('Server running on http://localhost:8080');

  await for (HttpRequest request in server) {
    if (request.method == 'GET' && request.uri.path == '/') {
      final query = request.uri.queryParameters['search'] ?? '';
      final filteredOrders = query.isEmpty
          ? orders
          : orders.where((order) =>
              order.item.toLowerCase().contains(query.toLowerCase()) ||
              order.itemName.toLowerCase().contains(query.toLowerCase())).toList();

      request.response.headers.contentType = ContentType.html;
      request.response.write('''
  <!DOCTYPE html>
  <html>
  <head>
    <title>My Order</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
      body {
        background-color: #fdf5e6;
      }
      .navbar {
        background-color: #d2691e !important;
      }
      .card-header {
        background-color: #d2691e !important;
        color: white;
      }
      .btn-success, .btn-primary {
        background-color: #d2691e !important;
        border-color: #d2691e !important;
      }
      .btn-success:hover, .btn-primary:hover {
        background-color: #b85c17 !important;
        border-color: #b85c17 !important;
      }
      .delete-button {
        background: none;
        border: none;
        cursor: pointer;
      }
      .delete-button img {
        width: 20px;
        height: 20px;
      }
      .delete-button:hover img {
        filter: brightness(0.8);
      }
      table thead {
        background-color: #d2691e;
        color: white;
      }
      footer {
        background-color: #d2691e;
        color: white;
      }
    </style>
  </head>
  <body>
    <nav class="navbar navbar-expand-lg navbar-dark">
      <div class="container-fluid">
        <a class="navbar-brand" href="#">My Order</a>
      </div>
    </nav>
    <div class="container">
      <div class="card shadow-sm">
        <div class="card-header">
          <h5>Add New Order</h5>
        </div>
        <div class="card-body">
          <form method="POST" action="/add" class="row g-3">
            <div class="col-md-6">
              <label for="item" class="form-label">Item</label>
              <input type="text" class="form-control" id="item" name="item" required>
            </div>
            <div class="col-md-6">
              <label for="itemName" class="form-label">Item Name</label>
              <input type="text" class="form-control" id="itemName" name="itemName" required>
            </div>
            <div class="col-md-4">
              <label for="price" class="form-label">Price</label>
              <input type="number" class="form-control" id="price" name="price" required>
            </div>
            <div class="col-md-4">
              <label for="currency" class="form-label">Currency</label>
              <input type="text" class="form-control" id="currency" name="currency" placeholder="USD">
            </div>
            <div class="col-md-4">
              <label for="quantity" class="form-label">Quantity</label>
              <input type="number" class="form-control" id="quantity" name="quantity" required>
            </div>
            <div class="col-12">
              <button type="submit" class="btn btn-success w-100">Add Item</button>
            </div>
          </form>
        </div>
      </div>
      <div class="card shadow-sm mt-4">
        <div class="card-header">
          <h5>Order List</h5>
        </div>
        <div class="card-body">
          <form method="GET" action="/" class="row g-3 mb-3">
            <div class="col-md-10">
              <input type="text" name="search" class="form-control" placeholder="Search orders..." value="${query}">
            </div>
            <div class="col-md-2">
            
              <button type="submit" class="btn btn-primary w-100">Search</button>
            </div>
          </form>
          <table class="table table-striped">
            <thead>
              <tr>
                <th>Item</th>
                <th>Item Name</th>
                <th>Quantity</th>
                <th>Price</th>
                <th>Currency</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
''');
for (var order in filteredOrders) {
  request.response.write('''
              <tr>
                <td>${order.item}</td>
                <td>${order.itemName}</td>
                <td>${order.quantity}</td>
                <td>${order.price}</td>
                <td>${order.currency}</td>
                <td>
                  <form method="POST" action="/delete" style="display:inline;">
                
                    <input type="hidden" name="item" value="${order.item}">
                    <button type="submit" class="delete-button" title="Delete">
                      <img src="https://img.icons8.com/small/32/filled-trash.png" alt="Delete">
                    </button>
                  </form>
                </td>
              </tr>
  ''');
}
request.response.write('''
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <footer class="text-center py-3 mt-4">
      Số 8, Tôn Thất Thuyết, Cầu Giấy, Hà Nội
    </footer>
  </body>
  </html>
''');
      await request.response.close();
    } else if (request.method == 'POST' && request.uri.path == '/add') {
      final content = await utf8.decoder.bind(request).join();
      final data = Uri.splitQueryString(content);
      final newOrder = Order(
        item: data['item']!,
        itemName: data['itemName']!,
        price: double.parse(data['price']!),
        currency: data['currency']?.isEmpty ?? true ? 'USD' : data['currency']!,
        quantity: int.parse(data['quantity']!),
      );
      orders.add(newOrder);
      await file.writeAsString(jsonEncode(orders.map((o) => o.toJson()).toList()));
      request.response.redirect(Uri.parse('/'));
    } else if (request.method == 'POST' && request.uri.path == '/delete') {
      final content = await utf8.decoder.bind(request).join();
      final data = Uri.splitQueryString(content);
      final itemToDelete = data['item'];
      orders.removeWhere((order) => order.item == itemToDelete);
      await file.writeAsString(jsonEncode(orders.map((o) => o.toJson()).toList()));
      request.response.redirect(Uri.parse('/'));
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }
}