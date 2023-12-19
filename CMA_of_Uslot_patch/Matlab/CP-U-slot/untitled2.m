% 创建一个简单的数据集
x = 1:10;
y = x.^2;

% 绘制数据
plot(x, y);

% 给定x值
x_value = 5;

% 查找给定x值在x向量中的索引
index = find(x == x_value);

% 标记给定x值在图形上
hold on
plot(x(index), y(index), 'ro', 'MarkerSize', 10);
text(x(index), y(index), ['(' num2str(x(index)) ', ' num2str(y(index)) ')'], 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom')
hold off
