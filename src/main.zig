// Copyright (C) 2023 William Welna (wwelna@occultusterra.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

const bf_machine = struct {
    const Self = @This();
    const size:usize = 5000;
    const exeParam = struct {
        program_pos:usize = 0,
        loop:bool = false,
        loop_start:usize = 0,
    };
    const Fail = error {
        Odd_Brackets,
    };
    mem:[]u8,
    pos:usize,
    program:[]const u8,
    allocator:std.mem.Allocator,

    pub fn init(allocator:std.mem.Allocator, program:[]const u8) !Self {
        var mem = try allocator.alloc(u8, size);
        for(mem) |*x| { // allocator doesn't make sure any of this is actually zero
            x.* = 0;
        }
        return .{
            .program = program,
            .mem = mem,
            .allocator = allocator,
            .pos = 0,
        };
    }

    pub fn bracket_check(program:[]const u8) bool {
        var pos = 0;
        var open = 0;
        var closed = 0;
        while(pos < program.len-1) {
            switch(program[pos]) {
                '[' => {open += 1;},
                ']' => {closed += 1;},
                else => {},
            }
        }
        if(open == closed) return false else return true;
    }

    pub fn execute(self:*Self, param:exeParam) !usize { 
        var program_pos = param.program_pos;
        while(program_pos < self.program.len-1) {
            switch(self.program[program_pos]) {
                '>' => {self.pos += 1; program_pos += 1;},
                '<' => {self.pos -= 1; program_pos += 1;},
                '+' => {self.mem[self.pos] += 1; program_pos += 1;},
                '-' => {self.mem[self.pos] -= 1; program_pos += 1;},
                '.' => {try stdout.print("{c}", .{self.mem[self.pos]}); program_pos += 1;},
                ',' => {},
                '[' => {
                    program_pos += 1;
                    program_pos = try self.execute(.{.program_pos = program_pos, .loop = true, .loop_start = program_pos});
                },
                ']' => {
                    if(param.loop == true) {
                        if(self.mem[self.pos] == 0) {
                            return program_pos + 1;
                        } else program_pos = param.loop_start;
                    } else return Fail.Odd_Brackets; // Loop / Bracket count not even
                },
                else => {program_pos += 1;},
            }
        }
        return self.program.len-1;
    }

    pub fn deinit(self:*Self) void {
        self.allocator.free(self.mem);
    }

};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var program:std.ArrayList(u8) = std.ArrayList(u8).init(allocator);
    defer program.deinit();
    var input:[1]u8 = undefined;
    
    while(try stdin.readAll(&input) > 0) try program.append(input[0]);

    var bf = try bf_machine.init(allocator, program.items);
    defer bf.deinit();
    _ = try bf.execute(.{});
}