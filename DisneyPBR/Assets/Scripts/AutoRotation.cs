
using System;
using UnityEngine;

public class AutoRotation : MonoBehaviour
{
    public float speed = 0.5f;
    private void Update()
    {
        transform.Rotate(Vector3.up, speed);
    }
}
