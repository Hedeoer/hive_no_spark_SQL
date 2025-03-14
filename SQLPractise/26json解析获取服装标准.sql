
-- hive 3.1.3版本
-- json解析获取 ‘服装标准尺寸’的 sizelist
-- ["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL","4XL","5XL","6XL","7XL"]
with collect as (
    select
        '{"collectId":"farfetchcn_4bc68f664f1a03d79366a7c667993627_20240305191718","collectTime":"20240305191718","data":{"attributes":"","brandName":"WARDROBE.NYC","category":"女士西装/WARDROBE.NYC/女装/西装夹克","color":"中性色","country":"","currency":"CNY","dataSource":"farfetch-cn","discountedPrice":"16447.0","itemNumber":"W4043R12","material":"表面：羊毛, 衬里：粘胶纤维","newProductImgLinks":["https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","https://yuxingShoping1f8c975d69dfc3066770002f478c3bfb/","https://yuxingShopingad3be1e6ec6a2edc3d922951c522eb/","https://yuxingShoping5bef91b8aa001506eb3400646db51e8f/","https://yuxingShoping99c7f8fc6b051ec0afdb723613465051/","https://yuxingShoping72bf871ae95662e58f8d73b8cf06b76e/"],"productImgLinks":["https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287188_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287186_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287189_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287187_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287192_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287200_1000.jpg"],"productMainUrl":"https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","productName":"WARDROBE.NYC Contour 双排扣西装夹克","productRetailPrice":"16447.0","productUrl":"https://www.farfetch.cn/cn/shopping/women/wardrobenyc-contour-item-19404158.aspx","region":"美国","releaseDate":"","size":[{"sizeList":["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL","4XL","5XL","6XL","7XL"],"sizeStandardName":"服装标准尺寸"},{"sizeList":["36","38","40","42","44","46","48","50","52","54","56","58","60"],"sizeStandardName":"意大利码"},{"sizeList":["32","34","36","38","40","42","44","46","48","50","52","54","56"],"sizeStandardName":"法国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"英国码"},{"sizeList":["0","2","4","6","8","10","12","14","16","18","20","22"],"sizeStandardName":"美国码"},{"sizeList":["30","32","34","36","38","40","42","44","46","48","50","52","54"],"sizeStandardName":"德国码"},{"sizeList":["PP","PP","P","M","M","G","GG","GG","XGG","XGG","XGG","XGG"],"sizeStandardName":"巴西码"},{"sizeList":["34","36","38","40","42","44","46","48","50","52","54","56","58"],"sizeStandardName":"巴西"},{"sizeList":["3","5","7","9","11","13","15","17","19","21","23","25","27"],"sizeStandardName":"日本码"},{"sizeList":["000","00","0","1","2","3","4","5","6","7","8","9","10"],"sizeStandardName":"标准尺寸"},{"sizeList":["000","00","0","I","II","III","IV","V","VI","VII","VIII","IX","X"],"sizeStandardName":"罗马数字"},{"sizeList":["38","40","42","44","46","48","50","52","54","56","58","60","62"],"sizeStandardName":"俄罗斯码"},{"sizeList":[null,"33","44","55","66","77","88","99",null,null,null,null,null],"sizeStandardName":"韩国码"},{"sizeList":["145/73A","150/76A","155/80A","160/84A","165/88A","170/92A","175/96A","180/100A","185/104A",null,null,null,null],"sizeStandardName":"中国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"澳大利亚码"}]},"skuId":"","spuId":"19404158","style":"","targetPopulation":""}'
    as json_str
),
    size_elements as (
        select
            get_json_object(json_str,'$.data.size[0]') size_element
        from collect
    )
select
    get_json_object(size_element,'$.sizeList') size_list
from size_elements;

-- 获取有多少中服装标准
-- +--------------+---------------------------------------------------------------------------------------------------+
-- |standard_count|standard_names                                                                                     |
-- +--------------+---------------------------------------------------------------------------------------------------+
-- |15            |["中国码","俄罗斯码","巴西","巴西码","德国码","意大利码","日本码","服装标准尺寸","标准尺寸","法国码","澳大利亚码","罗马数字","美国码","英国码","韩国码"]|
-- +--------------+---------------------------------------------------------------------------------------------------+
with collect as (
    select
        '{"collectId":"farfetchcn_4bc68f664f1a03d79366a7c667993627_20240305191718","collectTime":"20240305191718","data":{"attributes":"","brandName":"WARDROBE.NYC","category":"女士西装/WARDROBE.NYC/女装/西装夹克","color":"中性色","country":"","currency":"CNY","dataSource":"farfetch-cn","discountedPrice":"16447.0","itemNumber":"W4043R12","material":"表面：羊毛, 衬里：粘胶纤维","newProductImgLinks":["https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","https://yuxingShoping1f8c975d69dfc3066770002f478c3bfb/","https://yuxingShopingad3be1e6ec6a2edc3d922951c522eb/","https://yuxingShoping5bef91b8aa001506eb3400646db51e8f/","https://yuxingShoping99c7f8fc6b051ec0afdb723613465051/","https://yuxingShoping72bf871ae95662e58f8d73b8cf06b76e/"],"productImgLinks":["https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287188_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287186_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287189_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287187_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287192_1000.jpg","https://cdn-images.farfetch-contents.com/19/40/41/58/19404158_50287200_1000.jpg"],"productMainUrl":"https://yuxingShoping517d4465ee74b5ca8d3805592b1c71fd/","productName":"WARDROBE.NYC Contour 双排扣西装夹克","productRetailPrice":"16447.0","productUrl":"https://www.farfetch.cn/cn/shopping/women/wardrobenyc-contour-item-19404158.aspx","region":"美国","releaseDate":"","size":[{"sizeList":["XXXS","XXS","XS","S","M","L","XL","XXL","XXXL","4XL","5XL","6XL","7XL"],"sizeStandardName":"服装标准尺寸"},{"sizeList":["36","38","40","42","44","46","48","50","52","54","56","58","60"],"sizeStandardName":"意大利码"},{"sizeList":["32","34","36","38","40","42","44","46","48","50","52","54","56"],"sizeStandardName":"法国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"英国码"},{"sizeList":["0","2","4","6","8","10","12","14","16","18","20","22"],"sizeStandardName":"美国码"},{"sizeList":["30","32","34","36","38","40","42","44","46","48","50","52","54"],"sizeStandardName":"德国码"},{"sizeList":["PP","PP","P","M","M","G","GG","GG","XGG","XGG","XGG","XGG"],"sizeStandardName":"巴西码"},{"sizeList":["34","36","38","40","42","44","46","48","50","52","54","56","58"],"sizeStandardName":"巴西"},{"sizeList":["3","5","7","9","11","13","15","17","19","21","23","25","27"],"sizeStandardName":"日本码"},{"sizeList":["000","00","0","1","2","3","4","5","6","7","8","9","10"],"sizeStandardName":"标准尺寸"},{"sizeList":["000","00","0","I","II","III","IV","V","VI","VII","VIII","IX","X"],"sizeStandardName":"罗马数字"},{"sizeList":["38","40","42","44","46","48","50","52","54","56","58","60","62"],"sizeStandardName":"俄罗斯码"},{"sizeList":[null,"33","44","55","66","77","88","99",null,null,null,null,null],"sizeStandardName":"韩国码"},{"sizeList":["145/73A","150/76A","155/80A","160/84A","165/88A","170/92A","175/96A","180/100A","185/104A",null,null,null,null],"sizeStandardName":"中国码"},{"sizeList":["4","6","8","10","12","14","16","18","20","22","24","26","28"],"sizeStandardName":"澳大利亚码"}]},"skuId":"","spuId":"19404158","style":"","targetPopulation":""}'
    as json_str
),
-- 提取size数组并统计服装标准种类
 size_data AS (
  SELECT get_json_object(json_str, '$.data.size') as size_array
  FROM collect
),
size_items AS (
  SELECT
    get_json_object( '{' || size_item || '}', '$.sizeStandardName') as standard_name
  FROM size_data
  LATERAL VIEW explode(split(regexp_replace(regexp_replace(size_array, '\\[\\{', ''), '\\}\\]', ''), '\\},\\{')) items AS size_item
)
SELECT
  COUNT(DISTINCT standard_name) as standard_count,
  collect_set(standard_name) as standard_names
FROM size_items
WHERE standard_name IS NOT NULL;
