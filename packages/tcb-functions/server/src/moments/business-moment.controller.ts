import { Controller, Get, HttpCode, HttpStatus, Query } from "@nestjs/common";
import { CloudBaseService } from "src/cloudbase/cloudbase.service";
import { Auth } from "src/users/auth.decorator";
import { UserDto } from "src/users/dtos/user.dto";

@Controller('moment-business')
export class BusinessMomentController {
    constructor(
        private readonly tcb: CloudBaseService,
    ) {}

    @Get('following')
    @HttpCode(HttpStatus.OK)
    async following(
        @Auth() user: UserDto,
        @Query('limit') limit: any  = 20,
        @Query('offset') offset: any = 0,
    ) {
        const db = this.tcb.server.database();
        const _ = db.command;
        
        const query = db.collection('moments')
            .aggregate()
            .lookup({
                from: 'user-follow',
                as: 'follow',
                let: { userId: '$userId' },
                pipeline: _.aggregate.pipeline().match(_.expr(
                    _.aggregate.add([
                        _.aggregate.eq(['$userId', user.uid]),
                        _.aggregate.eq(['$targetUserId', '$$userId']),
                    ]),
                )).project({
                    _id: false,
                    targetUserId: true,
                }).done(),
            })
            .lookup({
                from: 'topic-user',
                as: 'topics',
                let: { topicId: '$topicId' },
                pipeline: _.aggregate.pipeline().match(_.expr(
                    _.aggregate.and([
                        _.aggregate.eq(['$userId', user.uid]),
                        _.aggregate.eq(['$topicId', '$$topicId']),
                    ]),
                )).project({
                    _id: false,
                    topicId: true,
                }).done(),
            })
            .project({
                _id: false,
                id: '$_id',
                createdAt: true,
                userId: true,
                topicId: true,
                follow: _.aggregate.map({
                    input: '$follow',
                    in: '$$this.targetUserId',
                }),
                topics: _.aggregate.map({
                    input: '$topics',
                    in: '$$this.topicId',
                }),
            })
            .match(_.expr(
                _.aggregate.or([
                    _.aggregate.in(['$userId', '$follow']),
                    _.aggregate.in(['$topicId', '$topics']),
                    _.aggregate.eq(['$userId', user.uid]),
                ]),
            ))
            .project({
                id: true,
                createdAt: true,
            })
            // 聚合搜索条件顺序很重要。。。不想 MySQL 那样限定条件，如 limit 可以随意顺序！必须按步聚合！
            .sort({
                createdAt: -1,
            })
            .skip(parseInt(offset))
            .limit(parseInt(limit))
            .end();
        
        const result = await query;

        return result.data.map(e => e.id);
    }

    @Get('recommend')
    @HttpCode(HttpStatus.OK)
    async recommend(
        @Query('limit') limit: any  = 20,
        @Query('offset') offset: any = 0,
    ) {
        const db = this.tcb.server.database();
        const _ = db.command;
        const $ = _.aggregate;

        const weekAgo = Date.now() - 86400000 * 7;

        const query = db.collection('moments')
            .aggregate()
            .lookup({
                from: 'moment-liked-histories',
                as: 'likes',
                let: { id: '$_id' },
                pipeline: $.pipeline().match(_.expr(
                    $.and([
                        $.gte(['$createdAt', weekAgo]),
                        $.eq(['$$id', '$momentId']),
                    ])
                )).project({ _id: true, }).done(),
            })
            .lookup({
                from: 'moment-comments',
                as: 'comments',
                let: { id: '$_id' },
                pipeline: $.pipeline().match(_.expr(
                    $.and([
                        $.gte(['$createdAt', weekAgo]),
                        $.eq(['$$id', '$momentId']),
                    ]),
                )).project({ _id: true }).done(),
            })
            .project({
                _id: false,
                id: '$_id',
                createdAt: true,
                total: $.sum([
                    $.size('$likes'),
                    $.size('$comments'),
                ]),
            })
            // 聚合搜索条件顺序很重要。。。不想 MySQL 那样限定条件，如 limit 可以随意顺序！必须按步聚合！
            .sort({
                total: -1,
                createdAt: -1,
            })
            .skip(parseInt(offset))
            .limit(parseInt(limit))
            .end();
        
        const result = await query;

        return result.data.map(e => e.id);
    }
}
