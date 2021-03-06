/*  Title:      Pure/PIDE/editor.scala
    Author:     Makarius

General editor operations.
*/

package isabelle


abstract class Editor[Context]
{
  def session: Session
  def flush(hidden: Boolean = false, purge: Boolean = false): Unit
  def invoke(): Unit
  def invoke_generated(): Unit
  def current_context: Context
  def current_node(context: Context): Option[Document.Node.Name]
  def current_node_snapshot(context: Context): Option[Document.Snapshot]
  def node_snapshot(name: Document.Node.Name): Document.Snapshot
  def current_command(context: Context, snapshot: Document.Snapshot): Option[Command]

  def node_overlays(name: Document.Node.Name): Document.Node.Overlays
  def insert_overlay(command: Command, fn: String, args: List[String]): Unit
  def remove_overlay(command: Command, fn: String, args: List[String]): Unit

  abstract class Hyperlink {
    def external: Boolean = false
    def follow(context: Context): Unit
  }
  def hyperlink_command(
    focus: Boolean, snapshot: Document.Snapshot, id: Document_ID.Generic, offset: Symbol.Offset = 0)
      : Option[Hyperlink]
}

