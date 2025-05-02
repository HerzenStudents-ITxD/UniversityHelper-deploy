USE FeedbackDB;

-- Insert predefined feedback types if they don't exist
MERGE INTO Types AS target
USING (VALUES
    ('00000000-0000-0000-0000-000000000000', 0, N'{"ru": "Нет", "en": "None", "сn": "无"}', 1),
    ('11111111-1111-1111-1111-111111111112', 1, N'{"ru": "Пожелания", "en": "Wishes", "cn": "愿望"}', 1),
    ('22222222-2222-2222-2222-222222222222', 2, N'{"ru": "Главная", "en": "Home", "cn": "首页"}', 1),
    ('33333333-3333-3333-3333-333333333333', 3, N'{"ru": "Новости", "en": "News", "cn": "新闻"}', 1),
    ('44444444-4444-4444-4444-444444444444', 4, N'{"ru": "Маршруты", "en": "Routes", "cn": "路线"}', 1),
    ('55555555-5555-5555-5555-555555555555', 5, N'{"ru": "Расписание", "en": "Timetable", "cn": "课程表"}', 1),
    ('66666666-6666-6666-6666-666666666666', 6, N'{"ru": "Настройки", "en": "Settings", "cn": "设置"}', 1),
    ('77777777-7777-7777-7777-777777777777', 7, N'{"ru": "Другое", "en": "Other", "cn": "其他"}', 1)
) AS source (Id, Type, Name, IsActive)
ON target.Id = source.Id
WHEN NOT MATCHED THEN
    INSERT (Id, Type, Name, IsActive)
    VALUES (source.Id, source.Type, source.Name, source.IsActive);