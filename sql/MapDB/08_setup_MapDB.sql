USE MapDB;
GO

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @ModeratorUserId UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';

-- Main building points
DECLARE @MainEntranceId UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @ReceptionId UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';
DECLARE @LibraryId UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555555';
DECLARE @CafeteriaId UNIQUEIDENTIFIER = '66666666-6666-6666-6666-666666666666';
DECLARE @Auditorium1Id UNIQUEIDENTIFIER = '77777777-7777-7777-7777-777777777777';
DECLARE @Auditorium2Id UNIQUEIDENTIFIER = '88888888-8888-8888-8888-888888888888';
DECLARE @DeanOfficeId UNIQUEIDENTIFIER = '99999999-9999-9999-9999-999999999999';
DECLARE @ComputerLabId UNIQUEIDENTIFIER = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA';
DECLARE @ParkingLotId UNIQUEIDENTIFIER = 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB';
DECLARE @SportsHallId UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC';

-- Label IDs
DECLARE @PublicAreaLabelId UNIQUEIDENTIFIER = 'DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD';
DECLARE @StudyAreaLabelId UNIQUEIDENTIFIER = 'EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE';
DECLARE @AdministrativeLabelId UNIQUEIDENTIFIER = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';
DECLARE @AccessibleLabelId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
DECLARE @FoodLabelId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111112';
DECLARE @TechLabelId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111113';

-- Point Type IDs
DECLARE @BuildingEntranceTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111114';
DECLARE @ReceptionTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111115';
DECLARE @LibraryTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111116';
DECLARE @CafeteriaTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111117';
DECLARE @AuditoriumTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111118';
DECLARE @OfficeTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111119';
DECLARE @ComputerLabTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111120';
DECLARE @ParkingTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111121';
DECLARE @SportsFacilityTypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111122';
DECLARE @Floor1TypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111123';
DECLARE @Floor2TypeId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111124';

-- Create Labels (tags for filtering)
INSERT INTO Labels (Id, Name, CreatedBy, CreatedAtUtc, IsActive)
VALUES
-- Public areas label
(
    @PublicAreaLabelId,
    '{"ru": "Общественные зоны", "en": "Public Areas", "cn": "公共区域"}',
    @AdminUserId,
    @Now,
    1
),
-- Study areas label
(
    @StudyAreaLabelId,
    '{"ru": "Учебные зоны", "en": "Study Areas", "cn": "学习区"}',
    @AdminUserId,
    @Now,
    1
),
-- Administrative label
(
    @AdministrativeLabelId,
    '{"ru": "Административные", "en": "Administrative", "cn": "行政的"}',
    @AdminUserId,
    @Now,
    1
),
-- Accessible label
(
    @AccessibleLabelId,
    '{"ru": "Доступная среда", "en": "Accessible", "cn": "无障碍"}',
    @ModeratorUserId,
    @Now,
    1
),
-- Food label
(
    @FoodLabelId,
    '{"ru": "Питание", "en": "Food", "cn": "食品"}',
    @ModeratorUserId,
    @Now,
    1
),
-- Technology label
(
    @TechLabelId,
    '{"ru": "Технологии", "en": "Technology", "cn": "技术"}',
    @ModeratorUserId,
    @Now,
    1
);

-- Create Point Types (for categorization)
INSERT INTO PointTypes (Id, Name, Icon, CreatedBy, CreatedAtUtc, IsActive)
VALUES
-- Building entrance type
(
    @BuildingEntranceTypeId,
    '{"ru": "Вход в здание", "en": "Building Entrance", "cn": "建筑物入口"}',
    'entrance-icon',
    @AdminUserId,
    @Now,
    1
),
-- Reception type
(
    @ReceptionTypeId,
    '{"ru": "Ресепшен", "en": "Reception", "cn": "接待处"}',
    'reception-icon',
    @AdminUserId,
    @Now,
    1
),
-- Library type
(
    @LibraryTypeId,
    '{"ru": "Библиотека", "en": "Library", "cn": "图书馆"}',
    'library-icon',
    @AdminUserId,
    @Now,
    1
),
-- Cafeteria type
(
    @CafeteriaTypeId,
    '{"ru": "Кафетерий", "en": "Cafeteria", "cn": "自助餐厅"}',
    'cafeteria-icon',
    @AdminUserId,
    @Now,
    1
),
-- Auditorium type
(
    @AuditoriumTypeId,
    '{"ru": "Аудитория", "en": "Auditorium", "cn": "礼堂"}',
    'auditorium-icon',
    @AdminUserId,
    @Now,
    1
),
-- Office type
(
    @OfficeTypeId,
    '{"ru": "Офис", "en": "Office", "cn": "办公室"}',
    'office-icon',
    @AdminUserId,
    @Now,
    1
),
-- Computer lab type
(
    @ComputerLabTypeId, 
    '{"ru": "Компьютерный класс", "en": "Computer Lab", "cn": "计算机实验室"}',
    'computer-icon',
    @AdminUserId,
    @Now,
    1
),
-- Parking type
(
    @ParkingTypeId,
    '{"ru": "Парковка", "en": "Parking", "cn": "停车"}',
    'parking-icon',
    @AdminUserId,
    @Now,
    1
),
-- Sports facility type
(
    @SportsFacilityTypeId,
    '{"ru": "Спортивный зал", "en": "Sports Facility", "cn": "体育设施"}',
    'sports-icon',
    @AdminUserId,
    @Now,
    1
),
-- Floor 1 type
(
    @Floor1TypeId,
    '{"ru": "1 этаж", "en": "Floor 1", "cn": "1楼"}',
    'floor1-icon',
    @AdminUserId,
    @Now,
    1
),
-- Floor 2 type
(
    @Floor2TypeId,
    '{"ru": "2 этаж", "en": "Floor 2", "cn": "2楼"}',
    'floor2-icon',
    @AdminUserId,
    @Now,
    1
);

-- Create Point Type Associations (for search)
INSERT INTO PointTypeAssociations (Id, PointTypeId, Association, CreatedBy, CreatedAtUtc, IsActive)
VALUES
-- Building entrance associations
(NEWID(), @BuildingEntranceTypeId, '{"ru": "Главный вход", "en": "Main Entrance", "cn": "主入口"}', @AdminUserId, @Now, 1),
(NEWID(), @BuildingEntranceTypeId, '{"ru": "Дверь", "en": "Door", "cn": "门"}', @AdminUserId, @Now, 1),
-- Reception associations
(NEWID(), @ReceptionTypeId, '{"ru": "Справочная", "en": "Information", "cn": "信息"}', @AdminUserId, @Now, 1),
(NEWID(), @ReceptionTypeId, '{"ru": "Помощь", "en": "Help", "cn": "帮助"}', @AdminUserId, @Now, 1),
-- Library associations
(NEWID(), @LibraryTypeId, '{"ru": "Книги", "en": "Books", "cn": "书籍"}', @AdminUserId, @Now, 1),
(NEWID(), @LibraryTypeId, '{"ru": "Читальный зал", "en": "Reading Room", "cn": "阅览室"}', @AdminUserId, @Now, 1),
-- Cafeteria associations
(NEWID(), @CafeteriaTypeId, '{"ru": "Еда", "en": "Food", "cn": "食物"}', @AdminUserId, @Now, 1),
(NEWID(), @CafeteriaTypeId, '{"ru": "Обед", "en": "Lunch", "cn": "午餐"}', @AdminUserId, @Now, 1);

-- Create Point Type Bounding Boxes (for editor hints)
INSERT INTO PointTypeRectangularParallelepipeds (Id, PointTypeId, XMin, YMin, ZMin, XMax, YMax, ZMax, CreatedBy, CreatedAtUtc, IsActive)
VALUES
-- Floor 1 bounding box
(NEWID(), @Floor1TypeId, 0, 0, 0, 100, 100, 3, @AdminUserId, @Now, 1),
-- Floor 2 bounding box
(NEWID(), @Floor2TypeId, 0, 0, 3, 100, 100, 6, @AdminUserId, @Now, 1),
-- Computer lab bounding box
(NEWID(), @ComputerLabTypeId, 30, 40, 3, 50, 60, 3, @AdminUserId, @Now, 1);

-- Create Points (locations on the map)
INSERT INTO Points (Id, Name, X, Y, Z, Icon, CreatedBy, CreatedAtUtc, IsActive, Fact, Description)
VALUES
-- Main entrance (ground floor)
(
    @MainEntranceId,
    '{"ru": "Главный вход", "en": "Main Entrance", "cn": "主入口"}',
    10.0, 5.0, 0.0,
    'main-entrance-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "Основной вход в университет", "en": "Main university entrance", "cn": "大学正门"}',
    '{"ru": "Главный вход с охраной и турникетами", "en": "Main entrance with security and turnstiles", "cn": "设有保安和闸机的主入口"}'
),
-- Reception (ground floor)
(
    @ReceptionId,
    '{"ru": "Ресепшен", "en": "Reception", "cn": "接待处"}',
    15.0, 5.0, 0.0,
    'reception-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "Здесь можно получить информацию", "en": "Information available here", "cn": "可在此获取信息"}',
    '{"ru": "Центральный ресепшен с картами и справочными материалами", "en": "Central reception with maps and information materials", "cn": "中央接待处提供地图和信息资料"}'
),
-- Library (1st floor)
(
    @LibraryId,
    '{"ru": "Главная библиотека", "en": "Main Library", "cn": "主图书馆"}',
    25.0, 30.0, 3.0,
    'library-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "Более 100 000 книг и журналов", "en": "Over 100,000 books and journals", "cn": "超过10万册书籍和期刊"}',
    '{"ru": "Трехэтажная библиотека с читальными залами и компьютерной зоной", "en": "Three-story library with reading rooms and computer area", "cn": "三层图书馆，设有阅览室和电脑区"}'
),
-- Cafeteria (ground floor)
(
    @CafeteriaId,
    '{"ru": "Кафетерий", "en": "Cafeteria", "cn": "自助餐厅"}',
    40.0, 10.0, 0.0,
    'cafeteria-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "Открыт с 8:00 до 20:00", "en": "Open from 8:00 to 20:00", "cn": "开放时间8:00至20:00"}',
    '{"ru": "Столовая с горячими блюдами и салат-баром", "en": "Cafeteria with hot meals and salad bar", "cn": "提供热食和沙拉吧的自助餐厅"}'
),
-- Auditorium 1 (1st floor)
(
    @Auditorium1Id,
    '{"ru": "Аудитория 101", "en": "Auditorium 101", "cn": "101礼堂"}',
    50.0, 20.0, 3.0,
    'auditorium-icon',
    @ModeratorUserId,
    @Now,
    1,
    '{"ru": "Вместимость 120 человек", "en": "Capacity 120 people", "cn": "可容纳120人"}',
    '{"ru": "Лекционная аудитория с проектором и звуковой системой", "en": "Lecture hall with projector and sound system", "cn": "配有投影仪和音响系统的演讲厅"}'
),
-- Auditorium 2 (2nd floor)
(
    @Auditorium2Id,
    '{"ru": "Аудитория 201", "en": "Auditorium 201", "cn": "201礼堂"}',
    50.0, 20.0, 6.0,
    'auditorium-icon',
    @ModeratorUserId,
    @Now,
    1,
    '{"ru": "Вместимость 80 человек", "en": "Capacity 80 people", "cn": "可容纳80人"}',
    '{"ru": "Семинарная аудитория с круглым столом", "en": "Seminar room with round table", "cn": "带圆桌的研讨室"}'
),
-- Dean Office (2nd floor)
(
    @DeanOfficeId,
    '{"ru": "Офис декана", "en": "Dean Office", "cn": "院长办公室"}',
    60.0, 40.0, 6.0,
    'office-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "Приемные часы: 10:00-12:00, 14:00-16:00", "en": "Office hours: 10:00-12:00, 14:00-16:00", "cn": "办公时间10:00-12:00，14:00-16:00"}',
    '{"ru": "Кабинет декана факультета с приемной", "en": "Deans office with reception area", "cn": "院长办公室及接待区"}'
),
-- Computer Lab (1st floor)
(
    @ComputerLabId,
    '{"ru": "Компьютерный класс", "en": "Computer Lab", "cn": "计算机实验室"}',
    40.0, 50.0, 3.0,
    'computer-icon',
    @ModeratorUserId,
    @Now,
    1,
    '{"ru": "30 рабочих станций", "en": "30 workstations", "cn": "30个工作台"}',
    '{"ru": "Компьютерный класс с ПО для программирования", "en": "Computer lab with programming software", "cn": "配备编程软件的计算机实验室"}'
),
-- Parking Lot (outside, ground level)
(
    @ParkingLotId,
    '{"ru": "Парковка", "en": "Parking Lot", "cn": "停车场"}',
    5.0, 80.0, 0.0,
    'parking-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "50 парковочных мест", "en": "50 parking spaces", "cn": "50个停车位"}',
    '{"ru": "Охраняемая парковка для сотрудников и гостей", "en": "Guarded parking for staff and visitors", "cn": "为员工和访客提供的安保停车场"}'
),
-- Sports Hall (ground floor)
(
    @SportsHallId,
    '{"ru": "Спортивный зал", "en": "Sports Hall", "cn": "体育馆"}',
    70.0, 70.0, 0.0,
    'sports-icon',
    @AdminUserId,
    @Now,
    1,
    '{"ru": "Открыт для студентов с 7:00 до 22:00", "en": "Open for students from 7:00 to 22:00", "cn": "对学生开放时间7:00至22:00"}',
    '{"ru": "Спортивный зал с тренажерами и раздевалками", "en": "Sports hall with exercise equipment and changing rooms", "cn": "配有健身器材和更衣室的体育馆"}'
);

-- Create Point Associations (searchable terms for each point)
INSERT INTO PointAssociations (Id, PointId, Association)
VALUES
-- Main entrance associations
(NEWID(), @MainEntranceId, '{"ru": "Вход", "en": "Entrance", "cn": "入口"}'),
(NEWID(), @MainEntranceId, '{"ru": "Дверь", "en": "Door", "cn": "门"}'),
-- Reception associations
(NEWID(), @ReceptionId, '{"ru": "Информация", "en": "Information", "cn": "信息"}'),
(NEWID(), @ReceptionId, '{"ru": "Справка", "en": "Help Desk", "cn": "服务台"}'),
-- Library associations
(NEWID(), @LibraryId, '{"ru": "Книги", "en": "Books", "cn": "书籍"}'),
(NEWID(), @LibraryId, '{"ru": "Читальный зал", "en": "Reading Room", "cn": "阅览室"}'),
-- Cafeteria associations
(NEWID(), @CafeteriaId, '{"ru": "Еда", "en": "Food", "cn": "食物"}'),
(NEWID(), @CafeteriaId, '{"ru": "Обед", "en": "Lunch", "cn": "午餐"}');

-- Create Point Labels (tags for points)
INSERT INTO LabelPoints (Id, LabelId, PointId, CreatedBy, CreatedAtUtc, IsActive, Name)
VALUES
-- Main entrance labels
(NEWID(), @PublicAreaLabelId, @MainEntranceId, @AdminUserId, @Now, 1, 'Public Area'),
(NEWID(), @AccessibleLabelId, @MainEntranceId, @AdminUserId, @Now, 1, 'Accessible'),
-- Reception labels
(NEWID(), @PublicAreaLabelId, @ReceptionId, @AdminUserId, @Now, 1, 'Public Area'),
(NEWID(), @AccessibleLabelId, @ReceptionId, @AdminUserId, @Now, 1, 'Accessible'),
-- Library labels
(NEWID(), @StudyAreaLabelId, @LibraryId, @AdminUserId, @Now, 1, 'Study Area'),
(NEWID(), @PublicAreaLabelId, @LibraryId, @AdminUserId, @Now, 1, 'Public Area'),
-- Cafeteria labels
(NEWID(), @PublicAreaLabelId, @CafeteriaId, @AdminUserId, @Now, 1, 'Public Area'),
(NEWID(), @FoodLabelId, @CafeteriaId, @AdminUserId, @Now, 1, 'Food'),
-- Auditorium labels
(NEWID(), @StudyAreaLabelId, @Auditorium1Id, @AdminUserId, @Now, 1, 'Study Area'),
(NEWID(), @StudyAreaLabelId, @Auditorium2Id, @AdminUserId, @Now, 1, 'Study Area'),
-- Dean office labels
(NEWID(), @AdministrativeLabelId, @DeanOfficeId, @AdminUserId, @Now, 1, 'Administrative'),
-- Computer lab labels
(NEWID(), @StudyAreaLabelId, @ComputerLabId, @AdminUserId, @Now, 1, 'Study Area'),
(NEWID(), @TechLabelId, @ComputerLabId, @AdminUserId, @Now, 1, 'Technology'),
-- Parking labels
(NEWID(), @PublicAreaLabelId, @ParkingLotId, @AdminUserId, @Now, 1, 'Public Area'),
-- Sports hall labels
(NEWID(), @PublicAreaLabelId, @SportsHallId, @AdminUserId, @Now, 1, 'Public Area');

-- Create Point Photos
INSERT INTO Photos (Id, PointId, OrdinalNumber, CreatedBy, CreatedAtUtc, IsActive, Content)
VALUES
-- Main entrance photos
(NEWID(), @MainEntranceId, 1, @AdminUserId, @Now, 1, 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...'),
(NEWID(), @MainEntranceId, 2, @AdminUserId, @Now, 1, 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...'),
-- Library photos
(NEWID(), @LibraryId, 1, @ModeratorUserId, @Now, 1, 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...'),
-- Cafeteria photos
(NEWID(), @CafeteriaId, 1, @AdminUserId, @Now, 1, 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...');

-- Create Point Types (categorization)
INSERT INTO PointTypePoints (Id, PointTypeId, PointId)
VALUES
-- Main entrance types
(NEWID(), @BuildingEntranceTypeId, @MainEntranceId),
(NEWID(), @Floor1TypeId, @MainEntranceId),
-- Reception types
(NEWID(), @ReceptionTypeId, @ReceptionId),
(NEWID(), @Floor1TypeId, @ReceptionId),
-- Library types
(NEWID(), @LibraryTypeId, @LibraryId),
(NEWID(), @Floor1TypeId, @LibraryId),
-- Cafeteria types
(NEWID(), @CafeteriaTypeId, @CafeteriaId),
(NEWID(), @Floor1TypeId, @CafeteriaId),
-- Auditorium types
(NEWID(), @AuditoriumTypeId, @Auditorium1Id),
(NEWID(), @Floor1TypeId, @Auditorium1Id),
(NEWID(), @AuditoriumTypeId, @Auditorium2Id),
(NEWID(), @Floor2TypeId, @Auditorium2Id),
-- Dean office types
(NEWID(), @OfficeTypeId, @DeanOfficeId),
(NEWID(), @Floor2TypeId, @DeanOfficeId),
-- Computer lab types
(NEWID(), @ComputerLabTypeId, @ComputerLabId),
(NEWID(), @Floor1TypeId, @ComputerLabId),
-- Parking types
(NEWID(), @ParkingTypeId, @ParkingLotId),
-- Sports hall types
(NEWID(), @SportsFacilityTypeId, @SportsHallId),
(NEWID(), @Floor1TypeId, @SportsHallId);

-- Create Relations (paths between points)
PRINT 'Creating relations between points...';
INSERT INTO Relations (Id, FirstPointId, SecondPointId, CreatedBy, CreatedAtUtc, DbPointId)
VALUES
-- Path from main entrance to reception
(NEWID(), @MainEntranceId, @ReceptionId, @AdminUserId, @Now, NULL),
-- Path from reception to library (stairs)
(NEWID(), @ReceptionId, @LibraryId, @AdminUserId, @Now, NULL),
-- Path from reception to cafeteria
(NEWID(), @ReceptionId, @CafeteriaId, @AdminUserId, @Now, NULL),
-- Path from library to auditorium 1 (same floor)
(NEWID(), @LibraryId, @Auditorium1Id, @ModeratorUserId, @Now, NULL),
-- Path from auditorium 1 to auditorium 2 (stairs)
(NEWID(), @Auditorium1Id, @Auditorium2Id, @ModeratorUserId, @Now, NULL),
-- Path from auditorium 2 to dean office
(NEWID(), @Auditorium2Id, @DeanOfficeId, @AdminUserId, @Now, NULL),
-- Path from main entrance to parking lot
(NEWID(), @MainEntranceId, @ParkingLotId, @AdminUserId, @Now, NULL),
-- Path from main entrance to sports hall
(NEWID(), @MainEntranceId, @SportsHallId, @AdminUserId, @Now, NULL),
-- Path from cafeteria to computer lab
(NEWID(), @CafeteriaId, @ComputerLabId, @ModeratorUserId, @Now, NULL);

-- Verify setup
PRINT 'MapDB data setup completed';
PRINT 'Checking all data:';

# Basic verification of tables - updated to match actual table names
Write-Host "Performing basic table verification..."
$tablesToCheck = @("Points", "PointTypes", "Photos", "LabelPoints", "PointTypePoints", "Relations")

foreach ($table in $tablesToCheck) {
    try {
        $result = Invoke-SqlCmd -Query "SELECT TOP 1 Id FROM $table"
        if ($result -ne $false) {
            $count = Invoke-SqlCmd -Query "SELECT COUNT(*) AS Count FROM $table"
            Write-Host "[VERIFICATION] Table $table exists and contains $($count.Trim()) records"
        } else {
            Write-Warning "[VERIFICATION WARNING] Could not verify table $table"
        }
    } catch {
        Write-Warning "[VERIFICATION ERROR] Error verifying table $table`: $_"
    }
}

-- Check all labels
PRINT 'Labels:';
SELECT Id, Name, CreatedBy, CreatedAtUtc, IsActive FROM Labels;

-- Check all point types
PRINT 'Point Types:';
SELECT Id, Name, Icon, CreatedBy, CreatedAtUtc, IsActive FROM PointTypes;

-- Check all points
PRINT 'Points:';
SELECT Id, Name, X, Y, Z, Icon, CreatedBy, CreatedAtUtc, IsActive, Fact, Description FROM Points;

-- Check point associations
PRINT 'Point Associations:';
SELECT Id, PointId, Association FROM PointAssociations;

-- Check point labels
PRINT 'Point Labels:';
SELECT Id, LabelId, PointId, CreatedBy, CreatedAtUtc, IsActive, Name FROM LabelPoints;

-- Check point photos
PRINT 'Point Photos:';
SELECT Id, PointId, OrdinalNumber, CreatedBy, CreatedAtUtc, IsActive, Content FROM Photos;

-- Check point types
PRINT 'Point Type Points:';
SELECT Id, PointTypeId, PointId FROM PointTypePoints;

-- Check relations
PRINT 'Relations:';
SELECT Id, FirstPointId, SecondPointId, CreatedBy, CreatedAtUtc, DbPointId FROM Relations;

PRINT 'Setup verification completed';
GO