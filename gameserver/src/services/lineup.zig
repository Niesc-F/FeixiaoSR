const std = @import("std");
const protocol = @import("protocol");
const CmdID = protocol.CmdID;
const Session = @import("../Session.zig");
const Packet = @import("../Packet.zig");
const Allocator = std.mem.Allocator;
const Config = @import("config.zig");

pub fn onGetCurLineupData(session: *Session, _: *const Packet, allocator: Allocator) !void {
    const config = try Config.configLoader(allocator, "config.json");

    var lineup = protocol.LineupInfo.init(allocator);
    lineup.HPMGGECENEM = 5;
    lineup.plane_id = 5;
    lineup.KCLNAIMOFDL = 0;
    lineup.HPMGGECENEM = 5; //mp
    lineup.HGBHBGMMOKG = 5; //mp_max
    lineup.name = .{ .Const = "FeixiaoSR" };

    for (config.avatar_config.items, 0..) |avatarConf, idx| {
        var avatar = protocol.LineupAvatar.init(allocator);
        switch (avatarConf.id) {
            8001, 8002, 8003, 8004, 8005, 8006 => {
                avatar.id = avatarConf.id; // remap MC for initial lineup
            },
            else => {
                avatar.id = avatarConf.id;
            },
        }
        avatar.slot = @intCast(idx);
        avatar.satiety = 0;
        avatar.hp = avatarConf.hp * 100;
        avatar.sp = .{ .sp_cur = avatarConf.sp * 100, .sp_need = 10000 };
        avatar.avatar_type = protocol.AvatarType.AVATAR_FORMAL_TYPE;
        try lineup.avatar_list.append(avatar);
    }

    try session.send(CmdID.CmdGetCurLineupDataScRsp, protocol.GetCurLineupDataScRsp{
        .retcode = 0,
        .lineup = lineup,
    });
}

pub fn onChangeLineupLeader(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.ChangeLineupLeaderCsReq, allocator);

    try session.send(CmdID.CmdChangeLineupLeaderScRsp, protocol.ChangeLineupLeaderScRsp{
        .slot = req.slot,
        .retcode = 0,
    });
}

pub fn onReplaceLineup(session: *Session, packet: *const Packet, allocator: Allocator) !void {
    const req = try packet.getProto(protocol.ReplaceLineupCsReq, allocator);
    var lineup = protocol.LineupInfo.init(allocator);
    lineup.HPMGGECENEM = 5;
    lineup.HGBHBGMMOKG = 5;
    lineup.name = .{ .Const = "FeixiaoSR" };
    for (req.IPHNMDOIFON.items) |ok| {
        const avatar = protocol.LineupAvatar{
            .id = ok.id,
            .slot = ok.slot,
            .satiety = 0,
            .hp = 10000,
            .avatar_type = protocol.AvatarType.AVATAR_FORMAL_TYPE,
            .sp = .{ .sp_cur = 10000, .sp_need = 10000 },
        };
        try lineup.avatar_list.append(avatar);
    }
    var rsp = protocol.SyncLineupNotify.init(allocator);
    rsp.lineup = lineup;
    try session.send(CmdID.CmdSyncLineupNotify, rsp);

    try session.send(CmdID.CmdReplaceLineupScRsp, protocol.ReplaceLineupScRsp{
        .retcode = 0,
    });
}