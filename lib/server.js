const io = require('socket.io')(3000, {
  cors: {
    origin: '*',
  }
});

io.on('connection', (socket) => {
  console.log('New user connected: ', socket.id);

  socket.on('join', (room) => {
    socket.join(room);
    console.log('User joined room: ', room);
  });

  socket.on('signal', (data) => {
    io.to(data.room).emit('signal', data);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected: ', socket.id);
  });
});
