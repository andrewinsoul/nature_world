# 🌍 Nature World

> A living visualization of the BEAM runtime built with Elixir, Phoenix LiveView, and OTP.

Nature World started as a simple idea for my portfolio.

I wanted something more than another page with a profile picture, a list of projects, and a contact button. I wanted visitors to *experience* the way I think about software.

As backend engineers, we spend a lot of time talking about concepts like concurrency, message passing, supervision trees, and fault tolerance. They're fascinating topics, but they're also incredibly abstract. Unless you've worked with the BEAM before, it's difficult to develop an intuition for what is actually happening inside the runtime.

Nature World is my attempt to make those invisible concepts visible.

Instead of reading about independent processes communicating through asynchronous messages, you watch them. Instead of imagining GenServers exchanging messages, you see them. Instead of thinking about OTP as a collection of libraries, you experience it as a living ecosystem.

---



## Why I Built This

One of the things I've always admired about the BEAM is that it encourages us to think about software differently.

A process isn't a thread.

A process isn't an object.

A process is an independent actor with its own state that communicates only by sending messages.

That sounds simple until you actually watch hundreds of them interacting.

Nature World exists to bridge that gap.

It's not intended to be a scientifically accurate simulator of the BEAM scheduler. Instead, it's a visual intuition builder—a playground where concurrent systems become tangible.

---



## The Idea

Every glowing circle represents an independent process.

Every interaction is an asynchronous message.

Every highlighted citizen represents a process whose internal state has changed after receiving a message.

The simulation itself is driven entirely from the server.

The browser doesn't invent any state.

Instead, Phoenix LiveView continuously reflects the current state of the world while small JavaScript hooks are used only for visual animation.

That separation was intentional.

The server owns truth.

The client owns presentation.

---



## Architecture

At a high level the application looks like this:

```

┌─────────────────────┐
│   Citizen Process   │
│    (GenServer)      │
└─────────┬───────────┘
│
│ Message
▼
┌─────────────────────┐
│    Simulation       │
│     (GenServer)     │
└─────────┬───────────┘
│
│ PubSub Broadcast
▼
┌─────────────────────┐
│     LiveView        │
└─────────┬───────────┘
│
│ Render
▼
┌─────────────────────┐
│     Browser         │
│ Animation Hooks     │
└─────────────────────┘

```

-> The simulation owns the world.

-> Citizens own themselves.

-> LiveView mirrors the state.

-> JavaScript simply animates what already happened.

## Technologies

Nature World is intentionally built with a very small stack.

Elixir
OTP
Phoenix
Phoenix LiveView
Phoenix PubSub
Tailwind CSS

No frontend framework.
No client-side state management.
No REST polling.
No manually managed WebSocket connections.

Just the BEAM doing what it does best.

## Current Features

- Independent citizen processes
- Real-time server-driven simulation
- PubSub powered updates
- LiveView rendering
- Interactive process selection
- Message passing visualization
- Process state transitions
- Live system dashboard
- Responsive interface
- Animated message particles
- Ambient world rendering



## Design Philosophy

One design decision influenced almost every part of this project.

The browser should never be responsible for deciding the state of the world.

Instead,

the server determines:

where citizens are
when they communicate
what state they're in

The browser simply visualizes that information beautifully.

This keeps the architecture simple while still allowing rich animations.

## What's Next?

Nature World is only the beginning.

Some ideas currently on the roadmap include:

- Multiple message types
- Supervision tree visualization
- Process crashes and automatic restarts
- Scheduler visualization
- Telemetry overlays
- Distributed node simulation
- Interactive tutorials
- Time controls
- Process spawning
- Fault injection mode

Ultimately I'd love Nature World to become an educational playground for understanding the BEAM.

## Running Locally

```bash
git clone https://github.com/<your-username>/nature_world.git

cd nature_world

mix deps.get

mix phx.server
```

Visit

```
http://localhost:4000
```



## About Me

Hi 👋

I'm Andrew Okoye, a backend engineer with a passion for building resilient, concurrent, and distributed systems using Elixir, OTP, and Phoenix.

Nature World is one example of how I like to learn and share what I discover. Whether it's an interactive visualization of the BEAM, an open-source library, or a deep dive into how something works internally, I'm always looking for ways to turn complex engineering concepts into experiences that are practical, approachable, and hopefully a little fun.

If you enjoyed exploring Nature World, I'd love to stay connected.

- 📖 **Medium** — I regularly publish articles on Elixir, OTP, Phoenix, distributed systems, software architecture, and the lessons I learn while building.
- 💼 **LinkedIn** — I share engineering insights, open-source updates, and behind-the-scenes progress from the projects I'm working on.

Whether you're an experienced Elixir developer or you're just beginning your journey with the BEAM, I hope something I build or write helps you see these technologies from a new perspective.

Happy BEAMing! 🚀

---



### Let's Connect

- 📖 **Medium:** [medium.com/@nature.exs](https://medium.com/@nature.exs)
- 💼 **LinkedIn:** [linkedin.com/in/andrew-okoye-281261132](https://www.linkedin.com/in/andrew-okoye-281261132/)



## License

MIT