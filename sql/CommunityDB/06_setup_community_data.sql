USE CommunityDB;

-- Declare variables
DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @AdminUserId UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @StudentUserId UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @TeacherUserId UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';

-- Community IDs
DECLARE @AdminCommunityId UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555555';
DECLARE @StudentCouncilId UNIQUEIDENTIFIER = '66666666-6666-6666-6666-666666666666';
DECLARE @ScienceClubId UNIQUEIDENTIFIER = '77777777-7777-7777-7777-777777777777';
DECLARE @SportsClubId UNIQUEIDENTIFIER = '88888888-8888-8888-8888-888888888888';

-- News IDs
DECLARE @WelcomeNewsId UNIQUEIDENTIFIER = '99999999-9999-9999-9999-999999999999';
DECLARE @ElectionNewsId UNIQUEIDENTIFIER = 'AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA';
DECLARE @ConferenceNewsId UNIQUEIDENTIFIER = 'BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB';
DECLARE @TournamentNewsId UNIQUEIDENTIFIER = 'CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC';

-- Agent IDs
DECLARE @AdminAgentId UNIQUEIDENTIFIER = 'DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD';
DECLARE @StudentAgentId UNIQUEIDENTIFIER = 'EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE';
DECLARE @ScienceAgentId UNIQUEIDENTIFIER = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';
DECLARE @SportsAgentId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';

-- Point IDs (for News)
DECLARE @Point1Id UNIQUEIDENTIFIER = '11110000-1111-1111-1111-111111111111';
DECLARE @Point2Id UNIQUEIDENTIFIER = '22220000-2222-2222-2222-222222222222';
DECLARE @Point3Id UNIQUEIDENTIFIER = '33330000-3333-3333-3333-333333333333';
DECLARE @Point4Id UNIQUEIDENTIFIER = '44440000-4444-4444-4444-444444444444';

-- Create communities
INSERT INTO Communities (Id, Name, Avatar, Text, CreatedBy, CreatedAtUtc, ModifiedBy, ModifiedAtUtc, IsHidden)
VALUES 
-- Admin community
(
    @AdminCommunityId,
    'University Administration',
    'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7',
    'Official community for university administration',
    @AdminUserId,
    @Now,
    @AdminUserId,
    @Now,
    0
),
-- Student council
(
    @StudentCouncilId,
    'Student Council',
    'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7',
    'Student government and activities',
    @StudentUserId,
    @Now,
    @StudentUserId,
    @Now,
    0
),
-- Science club
(
    @ScienceClubId,
    'Science Club',
    'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7',
    'Science research and events',
    @TeacherUserId,
    @Now,
    @TeacherUserId,
    @Now,
    0
),
-- Sports club
(
    @SportsClubId,
    'Sports Club',
    'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7',
    'University sports teams and events',
    @StudentUserId,
    @Now,
    @StudentUserId,
    @Now,
    0
);

-- Add community agents
INSERT INTO Agents (Id, AgentId, CommunityId)
VALUES 
-- Admin community agents
(NEWID(), @AdminAgentId, @AdminCommunityId),
(NEWID(), @TeacherUserId, @AdminCommunityId),
-- Student council agents
(NEWID(), @StudentAgentId, @StudentCouncilId),
(NEWID(), @StudentUserId, @StudentCouncilId),
-- Science club agents
(NEWID(), @ScienceAgentId, @ScienceClubId),
(NEWID(), @TeacherUserId, @ScienceClubId),
-- Sports club agents
(NEWID(), @SportsAgentId, @SportsClubId),
(NEWID(), @StudentUserId, @SportsClubId);

-- Add hidden communities (users hiding certain communities)
INSERT INTO HiddenCommunities (Id, UserId, CommunityId)
VALUES
-- Student hides admin community
(NEWID(), @StudentUserId, @AdminCommunityId),
-- Teacher hides sports club
(NEWID(), @TeacherUserId, @SportsClubId);

-- Create news for each community
INSERT INTO News (Id, Date, Title, Text, AuthorId, PointId, CommunityId, CreatedBy, CreatedAtUtc, ModifiedBy, ModifiedAtUtc)
VALUES
-- Admin community news
(
    @WelcomeNewsId,
    @Now,
    'Welcome to University Helper',
    'Welcome to our new platform! This is the official announcement from the university administration. We are excited to introduce new features for better communication and organization.',
    @AdminUserId,
    @Point1Id,
    @AdminCommunityId,
    @AdminUserId,
    @Now,
    @AdminUserId,
    @Now
),
-- Student council news
(
    @ElectionNewsId,
    DATEADD(DAY, -2, @Now),
    'Student Council Elections',
    'Annual student council elections will be held next week. All students are encouraged to participate and vote for their representatives.',
    @StudentUserId,
    @Point2Id,
    @StudentCouncilId,
    @StudentUserId,
    DATEADD(DAY, -2, @Now),
    @StudentUserId,
    DATEADD(DAY, -2, @Now)
),
-- Science club news
(
    @ConferenceNewsId,
    DATEADD(DAY, -5, @Now),
    'Annual Science Conference',
    'The Science Club is organizing its annual conference next month. Submit your research proposals by the end of this week.',
    @TeacherUserId,
    @Point3Id,
    @ScienceClubId,
    @TeacherUserId,
    DATEADD(DAY, -5, @Now),
    @TeacherUserId,
    DATEADD(DAY, -5, @Now)
),
-- Sports club news
(
    @TournamentNewsId,
    DATEADD(DAY, -1, @Now),
    'Basketball Tournament',
    'Inter-department basketball tournament starts next Monday. Register your teams by Friday!',
    @StudentUserId,
    @Point4Id,
    @SportsClubId,
    @StudentUserId,
    DATEADD(DAY, -1, @Now),
    @StudentUserId,
    DATEADD(DAY, -1, @Now)
);

-- Add news photos
INSERT INTO NewsPhoto (Id, Photo, NewsId)
VALUES
-- Admin news photo
(NEWID(), 'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7', @WelcomeNewsId),
-- Student council photo
(NEWID(), 'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7', @ElectionNewsId),
-- Science club photo
(NEWID(), 'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7', @ConferenceNewsId),
-- Sports club photo
(NEWID(), 'data:image/gif;base64,R0lGODlhBwAKAMIEAICAgJmZmbOzs/f39////////////////yH5BAEKAAcALAAAAAAHAAoAAAMWSDPUGoE5AaIj1M4qMW+ZFDYD1ClnAgA7', @TournamentNewsId);

-- Add news participants
INSERT INTO Participating (Id, UserId, NewsId)
VALUES
-- Admin news participants
(NEWID(), @AdminUserId, @WelcomeNewsId),
(NEWID(), @TeacherUserId, @WelcomeNewsId),
-- Student council news participants
(NEWID(), @StudentUserId, @ElectionNewsId),
(NEWID(), @StudentAgentId, @ElectionNewsId),
-- Science club news participants
(NEWID(), @TeacherUserId, @ConferenceNewsId),
(NEWID(), @ScienceAgentId, @ConferenceNewsId),
-- Sports club news participants
(NEWID(), @StudentUserId, @TournamentNewsId),
(NEWID(), @SportsAgentId, @TournamentNewsId);

-- Verify setup
PRINT 'Community data setup completed';
PRINT 'Checking all data:';

-- Check all communities
PRINT 'Communities:';
SELECT * FROM Communities;

-- Check all agents
PRINT 'Agents:';
SELECT * FROM Agents;

-- Check hidden communities
PRINT 'Hidden Communities:';
SELECT * FROM HiddenCommunities;

-- Check all news
PRINT 'News:';
SELECT * FROM News;

-- Check news photos
PRINT 'News Photos:';
SELECT * FROM NewsPhoto;

-- Check participants
PRINT 'Participants:';
SELECT * FROM Participating;