/*
种怎么解析出来upc、poiCoverIds、activityStatus、childActivityId这四个字段
*/
-- 方式1 ，如果json结构固定，使用from_json函数
WITH raw_data AS (
    SELECT '[{"upc":"4891214699106","groupNumber":2,"poiCoverIds":[27328289,27177717,27641161,27273825,27397427,27143163,27286728,27202288,27380897,27270871,27410428,27531096,27181919,27622791,27473153,27364924,27665032,27428734,27661498,27250113],"productName":"自然派 蜜汁猪肉条 65克/袋","subsidyType":"GOODS_RETURN","activityInfo":[{"activityStatus":"CREATE_DRAFT","childActivityId":63623316},{"activityStatus":"CREATE_DRAFT","childActivityId":63220296}],"subsidyDetail":"单品补贴额每单件1.2元"},{"upc":"6924509900767","groupNumber":3,"poiCoverIds":[27328289,27177717,27641161,27273825,27397427,27143163,27286728,27202288,27380897,27270871,27410428,27531096,27181919,27622791,27473153,27364924,27665032,27428734,27661498,27250113],"productName":"准盐 海藻碘食用盐 400g/袋","subsidyType":"GOODS_RETURN","activityInfo":[{"activityStatus":"CREATE_DRAFT","childActivityId":63625381},{"activityStatus":"CREATE_DRAFT","childActivityId":63220296}],"subsidyDetail":"单品补贴额每单件3元"}]'
               AS json_string
)
SELECT
    -- 从第一层展开的结构体中直接获取 upc
    t1_product.upc,
    -- 从第二层展开中获取 poiCoverIds (这是一个基本类型，不是结构体)
    t2_poi AS poiCoverIds,
    -- 从第三层展开的结构体中获取 activityStatus 和 childActivityId
    t3_activity.activityStatus,
    t3_activity.childActivityId
FROM
    raw_data

    -- 步骤1: 使用 from_json 和 schema 将整个字符串解析成一个 Hive 数组结构，并展开
    LATERAL VIEW explode(
            from_json(
                    json_string,
                    'ARRAY<STRUCT<upc:STRING, groupNumber:INT, poiCoverIds:ARRAY<BIGINT>, productName:STRING, subsidyType:STRING, activityInfo:ARRAY<STRUCT<activityStatus:STRING, childActivityId:BIGINT>>, subsidyDetail:STRING>>'
            )
                     ) t1 AS t1_product

        -- 步骤2: 展开每个产品结构体中的 poiCoverIds 数组
        LATERAL VIEW explode(t1_product.poiCoverIds) t2 AS t2_poi

        -- 步骤3: 展开每个产品结构体中的 activityInfo 数组
        LATERAL VIEW explode(t1_product.activityInfo) t3 AS t3_activity
;

-- 方式2，直接解析

select
    GET_JSON_OBJECT(a3,'$.upc') as upc,
    GET_JSON_OBJECT(a3,'$.poiCoverIds') as poiCoverIds,
    GET_JSON_OBJECT(a4,'$.activityStatus') as activityStatus,
    GET_JSON_OBJECT(a4,'$.childActivityId') as childActivityId
from (
         select
             a3,
             if(a4 is null, lead(a4,1) over(ORDER BY 1) ,a4) as a4
         from (
                  select
                      -- If the chunk contains "upc", it's the main object.
                      -- The split mangles the start/end brackets, so we replace '[{' with '{' and '}]' with '}' to make it a valid JSON object again.
                      if(a2 like '%upc%', replace(replace(a2, '[{', '{'), '}]', '}'), null) as a3,

                      -- If the chunk does NOT contain "upc", it's an activity object.
                      -- These chunks are missing the surrounding braces after the split, so we add them back with concat.
                      if(a2 not like '%upc%', concat('{', a2, '}'), null) as a4
                  from
                      (
                          select '[{"upc": "4891214699106", "groupNumber": 2, "poiCoverIds": [27328289, 27177717, 27641161, 27273825, 27397427, 27143163, 27286728, 27202288, 27380897, 27270871, 27410428, 27531096, 27181919, 27622791, 27473153, 27364924, 27665032, 27428734, 27661498, 27250113], "productName": "自然派 蜜汁猪肉条 65克/袋", "subsidyType": "GOODS_RETURN", "activityInfo": [{"activityStatus": "CREATE_DRAFT", "childActivityId": 63623316}, {"activityStatus": "CREATE_DRAFT", "childActivityId": 63220296}], "subsidyDetail": "单品补贴额每单件1.2元"}, {"upc": "6924509900767", "groupNumber": 3, "poiCoverIds": [27328289, 27177717, 27641161, 27273825, 27397427, 27143163, 27286728, 27202288, 27380897, 27270871, 27410428, 27531096, 27181919, 27622791, 27473153, 27364924, 27665032, 27428734, 27661498, 27250113], "productName": "淮盐 海藻碘食用盐 400g/袋", "subsidyType": "GOODS_RETURN", "activityInfo": [{"activityStatus": "CREATE_DRAFT", "childActivityId": 63625381}, {"activityStatus": "CREATE_DRAFT", "childActivityId": 63220296}], "subsidyDetail": "单品补贴额每单件3元"}]' as a
                      ) t1
                      lateral view explode(split(a,'},')) t2 as a2
              ) t3
     ) t4
where t4.a3 is not null;