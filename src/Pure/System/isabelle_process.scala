/*  Title:      Pure/System/isabelle_process.scala
    Author:     Makarius

Isabelle process wrapper.
*/

package isabelle


import java.io.{File => JFile}


object Isabelle_Process
{
  def start(session: Session,
    options: Options,
    logic: String = "",
    args: List[String] = Nil,
    dirs: List[Path] = Nil,
    modes: List[String] = Nil,
    cwd: JFile = null,
    env: Map[String, String] = Isabelle_System.settings(),
    sessions: Option[Sessions.T] = None,
    store: Sessions.Store = Sessions.store(),
    phase_changed: Session.Phase => Unit = null)
  {
    if (phase_changed != null)
      session.phase_changed += Session.Consumer("Isabelle_Process")(phase_changed)

    session.start(receiver =>
      Isabelle_Process(options, logic = logic, args = args, dirs = dirs, modes = modes,
        cwd = cwd, env = env, receiver = receiver, xml_cache = session.xml_cache,
        sessions = sessions, store = store))
  }

  def apply(
    options: Options,
    logic: String = "",
    args: List[String] = Nil,
    dirs: List[Path] = Nil,
    modes: List[String] = Nil,
    cwd: JFile = null,
    env: Map[String, String] = Isabelle_System.settings(),
    receiver: Prover.Receiver = Console.println(_),
    xml_cache: XML.Cache = new XML.Cache(),
    sessions: Option[Sessions.T] = None,
    store: Sessions.Store = Sessions.store()): Prover =
  {
    val channel = System_Channel()
    val process =
      try {
        ML_Process(options, logic = logic, args = args, dirs = dirs, modes = modes,
          cwd = cwd, env = env, sessions = sessions, store = store, channel = Some(channel))
      }
      catch { case exn @ ERROR(_) => channel.accepted(); throw exn }
    process.stdin.close

    new Prover(receiver, xml_cache, channel, process)
  }
}
