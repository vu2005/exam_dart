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

      // Calculate total values
      double totalValue = 0;
      int totalItems = 0;
      for (var order in filteredOrders) {
        totalValue += order.price * order.quantity;
        totalItems += order.quantity;
      }

      request.response.headers.contentType = ContentType.html;
      request.response.write('''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Quản Lý Đơn Hàng</title>
  <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    :root {
      --primary-color: #3498db;
      --secondary-color: #2980b9;
      --accent-color: #1abc9c;
      --light-color: #ecf0f1;
      --dark-color: #2c3e50;
    }
    
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f8f9fa;
      color: #333;
      line-height: 1.6;
    }
    
    .navbar {
      background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
      padding: 1rem 2rem;
    }
    
    .navbar-brand {
      font-weight: 700;
      font-size: 1.5rem;
      color: white !important;
    }
    
    .navbar-brand i {
      margin-right: 10px;
    }

    .main-container {
      max-width: 1200px;
      margin: 2rem auto;
      padding: 0 1rem;
    }
    
    .card {
      border: none;
      border-radius: 10px;
      box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
      margin-bottom: 2rem;
      overflow: hidden;
      transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    
    .card:hover {
      transform: translateY(-5px);
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
    }
    
    .card-header {
      background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
      color: white;
      font-weight: 600;
      padding: 1rem 1.5rem;
      border: none;
    }
    
    .card-header h5 {
      margin: 0;
      font-size: 1.2rem;
      display: flex;
      align-items: center;
    }
    
    .card-header h5 i {
      margin-right: 10px;
    }
    
    .card-body {
      padding: 1.5rem;
    }
    
    .form-label {
      font-weight: 500;
      margin-bottom: 0.5rem;
      color: var(--dark-color);
    }
    
    .form-control {
      border-radius: 8px;
      padding: 0.6rem 1rem;
      border: 1px solid #ddd;
      transition: border-color 0.3s ease, box-shadow 0.3s ease;
    }
    
    .form-control:focus {
      border-color: var(--primary-color);
      box-shadow: 0 0 0 0.25rem rgba(52, 152, 219, 0.25);
    }
    
    .btn {
      border-radius: 8px;
      padding: 0.6rem 1.5rem;
      font-weight: 500;
      transition: all 0.3s ease;
    }
    
    .btn-primary {
      background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
      border: none;
    }
    
    .btn-primary:hover, .btn-primary:focus {
      background: linear-gradient(135deg, var(--secondary-color), var(--primary-color));
      transform: translateY(-2px);
      box-shadow: 0 4px 10px rgba(52, 152, 219, 0.3);
    }
    
    .btn-success {
      background: linear-gradient(135deg, var(--accent-color), #16a085);
      border: none;
    }
    
    .btn-success:hover, .btn-success:focus {
      background: linear-gradient(135deg, #16a085, var(--accent-color));
      transform: translateY(-2px);
      box-shadow: 0 4px 10px rgba(26, 188, 156, 0.3);
    }
    
    .btn i {
      margin-right: 6px;
    }
    
    .table {
      border-radius: 10px;
      overflow: hidden;
      box-shadow: 0 0 10px rgba(0, 0, 0, 0.02);
    }
    
    .table thead {
      background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
      color: white;
    }
    
    .table thead th {
      font-weight: 600;
      border: none;
      padding: 1rem;
    }
    
    .table tbody tr {
      transition: background-color 0.3s ease;
    }
    
    .table tbody tr:hover {
      background-color: rgba(52, 152, 219, 0.05);
    }
    
    .table tbody td {
      vertical-align: middle;
      padding: 0.8rem 1rem;
      border-bottom: 1px solid #eee;
    }
    
    .action-buttons button {
      background: none;
      border: none;
      padding: 0.5rem;
      margin: 0 0.2rem;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      transition: all 0.3s ease;
      color: #777;
    }
    
    .action-buttons .edit-btn:hover {
      color: var(--primary-color);
      background-color: rgba(52, 152, 219, 0.1);
    }
    
    .action-buttons .delete-btn:hover {
      color: #e74c3c;
      background-color: rgba(231, 76, 60, 0.1);
    }
    
    .stats-container {
      display: flex;
      flex-wrap: wrap;
      gap: 1rem;
      margin-bottom: 2rem;
    }
    
    .stat-card {
      flex: 1;
      min-width: 250px;
      background: white;
      border-radius: 10px;
      padding: 1.5rem;
      box-shadow: 0 5px 15px rgba(0,0,0,0.05);
      display: flex;
      align-items: center;
    }
    
    .stat-icon {
      width: 50px;
      height: 50px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
      margin-right: 1rem;
      color: white;
    }
    
    .orders-icon {
      background: linear-gradient(135deg, #ff7675, #d63031);
    }
    
    .items-icon {
      background: linear-gradient(135deg, #74b9ff, #0984e3);
    }
    
    .value-icon {
      background: linear-gradient(135deg, #55efc4, #00b894);
    }
    
    .stat-info h3 {
      font-size: 1.8rem;
      font-weight: 700;
      margin: 0;
      color: var(--dark-color);
    }
    
    .stat-info p {
      color: #7f8c8d;
      margin: 0;
      font-size: 0.9rem;
    }
    
    .badge {
      font-weight: 500;
      padding: 0.5em 0.8em;
      border-radius: 6px;
    }
    
    .badge-price {
      background-color: rgba(26, 188, 156, 0.15);
      color: #16a085;
    }
    
    .badge-qty {
      background-color: rgba(52, 152, 219, 0.15);
      color: #2980b9;
    }
    
    .empty-state {
      text-align: center;
      padding: 3rem 1rem;
      color: #7f8c8d;
    }
    
    .empty-state i {
      font-size: 4rem;
      margin-bottom: 1rem;
      color: #bdc3c7;
    }
    
    .empty-state h4 {
      font-weight: 600;
      margin-bottom: 1rem;
    }
    
    footer {
      background: linear-gradient(135deg, var(--dark-color), #34495e);
      color: white;
      padding: 1.5rem 0;
      text-align: center;
      margin-top: 3rem;
    }
    
    footer p {
      margin: 0;
    }
    
    footer i {
      margin-right: 8px;
    }
    
    @media (max-width: 768px) {
      .stat-card {
        min-width: 100%;
      }
      
      .card-header h5 {
        font-size: 1.1rem;
      }
    }
  </style>
</head>
<body>
  <!-- Navbar -->
  <nav class="navbar navbar-expand-lg navbar-dark">
    <div class="container-fluid">
      <a class="navbar-brand" href="#">
        <i class="fas fa-shopping-cart"></i> Quản Lý Đơn Hàng
      </a>
    </div>
  </nav>

  <div class="main-container">
    <!-- Stats Cards -->
    <div class="stats-container">
      <div class="stat-card">
        <div class="stat-icon orders-icon">
          <i class="fas fa-file-invoice"></i>
        </div>
        <div class="stat-info">
          <h3>${filteredOrders.length}</h3>
          <p>Tổng số đơn hàng</p>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon items-icon">
          <i class="fas fa-box"></i>
        </div>
        <div class="stat-info">
          <h3>${totalItems}</h3>
          <p>Tổng số sản phẩm</p>
        </div>
      </div>
      
      <div class="stat-card">
        <div class="stat-icon value-icon">
          <i class="fas fa-dollar-sign"></i>
        </div>
        <div class="stat-info">
          <h3>\$${totalValue.toStringAsFixed(2)}</h3>
          <p>Tổng giá trị</p>
        </div>
      </div>
    </div>

    <!-- Add New Order -->
    <div class="card shadow-sm">
      <div class="card-header">
        <h5><i class="fas fa-plus-circle"></i> Thêm Đơn Hàng Mới</h5>
      </div>
      <div class="card-body">
        <form method="POST" action="/add" class="row g-3">
          <div class="col-md-6">
            <label for="item" class="form-label">Mã Sản Phẩm</label>
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-barcode"></i></span>
              <input type="text" class="form-control" id="item" name="item" placeholder="Ví dụ: A1234" required>
            </div>
          </div>
          
          <div class="col-md-6">
            <label for="itemName" class="form-label">Tên Sản Phẩm</label>
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-tag"></i></span>
              <input type="text" class="form-control" id="itemName" name="itemName" placeholder="Ví dụ: iPhone 15" required>
            </div>
          </div>
          
          <div class="col-md-4">
            <label for="price" class="form-label">Giá</label>
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-dollar-sign"></i></span>
              <input type="number" step="0.01" class="form-control" id="price" name="price" placeholder="0.00" required>
            </div>
          </div>
          
          <div class="col-md-4">
            <label for="currency" class="form-label">Đơn Vị Tiền Tệ</label>
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-coins"></i></span>
              <select class="form-control" id="currency" name="currency">
                <option value="USD">USD</option>
                <option value="EUR">EUR</option>
                <option value="VND">VND</option>
                <option value="JPY">JPY</option>
              </select>
            </div>
          </div>
          
          <div class="col-md-4">
            <label for="quantity" class="form-label">Số Lượng</label>
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-boxes"></i></span>
              <input type="number" class="form-control" id="quantity" name="quantity" min="1" value="1" required>
            </div>
          </div>
          
          <div class="col-12 mt-4">
            <button type="submit" class="btn btn-success w-100">
              <i class="fas fa-plus-circle"></i> Thêm Đơn Hàng
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Order List -->
    <div class="card shadow-sm">
      <div class="card-header">
        <h5><i class="fas fa-list"></i> Danh Sách Đơn Hàng</h5>
      </div>
      <div class="card-body">
        <form method="GET" action="/" class="row g-3 mb-4">
          <div class="col-md-10">
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-search"></i></span>
              <input type="text" name="search" class="form-control" placeholder="Tìm kiếm theo mã hoặc tên sản phẩm..." value="${query}">
            </div>
          </div>
          <div class="col-md-2">
            <button type="submit" class="btn btn-primary w-100">
              <i class="fas fa-search"></i> Tìm
            </button>
          </div>
        </form>

        <div class="table-responsive">
          <table class="table table-hover">
            <thead>
              <tr>
                <th scope="col">Mã SP</th>
                <th scope="col">Tên Sản Phẩm</th>
                <th scope="col">Số Lượng</th>
                <th scope="col">Đơn Giá</th>
                <th scope="col">Thành Tiền</th>
                <th scope="col">Thao Tác</th>
              </tr>
            </thead>
            <tbody>
''');

if (filteredOrders.isEmpty) {
  request.response.write('''
              <tr>
                <td colspan="6">
                  <div class="empty-state">
                    <i class="fas fa-box-open"></i>
                    <h4>Không tìm thấy đơn hàng</h4>
                    <p>Chưa có đơn hàng nào hoặc không tìm thấy kết quả phù hợp với tìm kiếm của bạn.</p>
                  </div>
                </td>
              </tr>
  ''');
} else {
  for (var order in filteredOrders) {
    final total = order.price * order.quantity;
    request.response.write('''
              <tr>
                <td>${order.item}</td>
                <td>${order.itemName}</td>
                <td><span class="badge badge-qty">${order.quantity}</span></td>
                <td><span class="badge badge-price">${order.currency} ${order.price.toStringAsFixed(2)}</span></td>
                <td><strong>${order.currency} ${total.toStringAsFixed(2)}</strong></td>
                <td>
                  <div class="action-buttons">
                    <form method="POST" action="/delete" style="display:inline;">
                      <input type="hidden" name="item" value="${order.item}">
                      <button type="submit" class="delete-btn" title="Xóa">
                        <i class="fas fa-trash-alt"></i>
                      </button>
                    </form>
                  </div>
                </td>
              </tr>
    ''');
  }
}

request.response.write('''
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <footer>
    <div class="container">
      <p><i class="fas fa-map-marker-alt"></i> Số 8, Tôn Thất Thuyết, Cầu Giấy, Hà Nội</p>
    </div>
  </footer>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.bundle.min.js"></script>
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